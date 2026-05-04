package com.managestress.app;
import android.Manifest;
import android.annotation.SuppressLint;
import android.os.Bundle;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.google.android.gms.auth.api.signin.GoogleSignIn;
import com.google.android.gms.auth.api.signin.GoogleSignInAccount;
import com.google.android.gms.auth.api.signin.GoogleSignInClient;
import com.google.android.gms.auth.api.signin.GoogleSignInOptions;
import com.google.android.gms.common.api.ApiException;
import com.google.android.gms.fitness.Fitness;
import com.google.android.gms.fitness.FitnessOptions;
import com.google.android.gms.fitness.data.Bucket;
import com.google.android.gms.fitness.data.DataPoint;
//import com.google.android.gms.fitness.data.DataReadRequest;
//import com.google.android.gms.fitness.data.DataReadResponse;
import com.google.android.gms.fitness.request.DataReadRequest;
import com.google.android.gms.fitness.result.DataReadResponse;
import com.google.android.gms.fitness.data.DataSet;
import com.google.android.gms.fitness.data.DataSource;
import com.google.android.gms.fitness.data.DataType;
import com.google.android.gms.fitness.data.Field;
import com.google.android.gms.tasks.Task;
import com.google.android.gms.tasks.Tasks;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import com.managestress.app.BuildConfig;

@SuppressWarnings({"deprecation", "unused"})
@SuppressLint({"NewApi", "MissingPermission"})
public class MainActivity extends FlutterActivity {
	private static final String CHANNEL = "stress_sense/google_fit";
	private static final int RC_SIGN_IN = 100;
	private static final int RC_FIT_PERMISSIONS = 7002;
	private static final int RC_RUNTIME_PERMISSIONS = 7003;
	private static final String TAG = "StressSenseAuth";

	private GoogleSignInClient googleSignInClient;
	private FitnessOptions fitnessOptions;

	private MethodChannel.Result pendingResult;
	private String pendingAction;

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);

		// Initialize Google Sign-In and FitnessOptions here. If the FlutterEngine
		// is not yet attached, skip MethodChannel registration to avoid null refs.
		final GoogleSignInOptions signInOptions = new GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
				.requestEmail()
				.build();
		googleSignInClient = GoogleSignIn.getClient(this, signInOptions);

		fitnessOptions = FitnessOptions.builder()
				.addDataType(DataType.TYPE_HEART_RATE_BPM, FitnessOptions.ACCESS_READ)
				.addDataType(DataType.TYPE_STEP_COUNT_DELTA, FitnessOptions.ACCESS_READ)
				.build();

		if (getFlutterEngine() != null && getFlutterEngine().getDartExecutor() != null) {
			new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(), CHANNEL)
					.setMethodCallHandler(this::handleMethodCall);
		} else {
			Log.w(TAG, "FlutterEngine not attached yet; MethodChannel registration deferred.");
		}
	}

	private void handleMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
		switch (call.method) {
			case "getAuthState":
				result.success(buildAuthState());
				break;
			case "signInInteractive":
				startSignInFlow(result);
				break;
			case "requestFitnessPermissions":
				requestFitnessPermissions(result);
				break;
			case "fetchLiveMetrics":
				fetchLiveMetrics(result);
				break;
			case "signOut":
				googleSignInClient.signOut().addOnCompleteListener(task -> result.success(true));
				break;
			default:
				result.notImplemented();
				break;
		}
	}

	private void startSignInFlow(@NonNull MethodChannel.Result result) {
		Log.d(TAG, "Login button flow triggered: starting Google Sign-In intent.");

		if (googleSignInClient == null) {
			Log.e(TAG, "GoogleSignInClient is null. Cannot start sign-in.");
			result.success(buildAuthStateWithMessage("Google Sign-In client was not initialized."));
			return;
		}

		if (pendingResult != null) {
			result.error("PENDING", "Another sign-in operation is already running.", null);
			return;
		}

		pendingResult = result;
		pendingAction = "signInInteractive";
		Log.d(TAG, "Calling startActivityForResult for Google Sign-In.");
		startActivityForResult(googleSignInClient.getSignInIntent(), RC_SIGN_IN);
	}

	private void requestFitnessPermissions(@NonNull MethodChannel.Result result) {
		GoogleSignInAccount account = GoogleSignIn.getLastSignedInAccount(this);
		if (account == null) {
			result.success(buildAuthState());
			return;
		}

		if (!hasRuntimePermissions()) {
			requestRuntimePermissions("requestFitnessPermissions", result);
			return;
		}

		ensureFitPermissions(account, "requestFitnessPermissions", result);
	}

	private void ensureFitPermissions(
			@NonNull GoogleSignInAccount account,
			@NonNull String action,
			@NonNull MethodChannel.Result result
	) {
		if (GoogleSignIn.hasPermissions(account, fitnessOptions)) {
			result.success(buildAuthState());
			return;
		}

		if (pendingResult != null) {
			result.error("PENDING", "Another permission operation is already running.", null);
			return;
		}

		pendingResult = result;
		pendingAction = action;
		GoogleSignIn.requestPermissions(this, RC_FIT_PERMISSIONS, account, fitnessOptions);
	}

	private void fetchLiveMetrics(@NonNull MethodChannel.Result result) {
		GoogleSignInAccount account = GoogleSignIn.getAccountForExtension(this, fitnessOptions);
		if (account == null) {
			result.success(buildErrorMetrics("User is not signed in."));
			return;
		}

		if (!hasRuntimePermissions()) {
			result.success(buildErrorMetrics("Activity/Sensor permissions are required."));
			return;
		}

		if (!GoogleSignIn.hasPermissions(account, fitnessOptions)) {
			result.success(buildErrorMetrics("Google Fit permission is not granted."));
			return;
		}

		long endTime = System.currentTimeMillis();
		long startTime = startOfDayMillis();

		DataReadRequest stepsRequest = new DataReadRequest.Builder()
				.aggregate(DataType.TYPE_STEP_COUNT_DELTA, DataType.AGGREGATE_STEP_COUNT_DELTA)
				.bucketByTime(1, TimeUnit.DAYS)
				.setTimeRange(startTime, endTime, TimeUnit.MILLISECONDS)
				.enableServerQueries()
				.build();

		DataReadRequest heartRateRequest = new DataReadRequest.Builder()
				.aggregate(DataType.TYPE_HEART_RATE_BPM, DataType.AGGREGATE_HEART_RATE_SUMMARY)
				.bucketByTime(1, TimeUnit.DAYS)
				.setTimeRange(startTime, endTime, TimeUnit.MILLISECONDS)
				.enableServerQueries()
				.build();

		Task<DataReadResponse> stepsTask = Fitness.getHistoryClient(this, account).readData(stepsRequest);
		Task<DataReadResponse> heartTask = Fitness.getHistoryClient(this, account).readData(heartRateRequest);

		Tasks.whenAllSuccess(stepsTask, heartTask)
				.addOnSuccessListener(responses -> {
					DataReadResponse stepsResponse = (DataReadResponse) responses.get(0);
					DataReadResponse heartResponse = (DataReadResponse) responses.get(1);

					int steps = extractSteps(stepsResponse);
					int heartRate = extractHeartRate(heartResponse);

					Map<String, Object> payload = new HashMap<>();
					payload.put("steps", steps);
					payload.put("heartRate", heartRate);
					payload.put("timestamp", System.currentTimeMillis());
					payload.put("permissionDenied", false);
					result.success(payload);
				})
				.addOnFailureListener(error -> result.success(buildErrorMetrics(error.getMessage())));
	}

	@Override
	protected void onActivityResult(int requestCode, int resultCode, Intent data) {
		super.onActivityResult(requestCode, resultCode, data);
		Log.d(TAG, "onActivityResult requestCode=" + requestCode + " resultCode=" + resultCode);

		if (requestCode == RC_SIGN_IN) {
			if (pendingResult == null) {
				return;
			}

			try {
				GoogleSignInAccount account = GoogleSignIn.getSignedInAccountFromIntent(data)
						.getResult(ApiException.class);
				if (account == null) {
					completePendingWithError("Sign-in was cancelled.");
					return;
				}

				if (GoogleSignIn.hasPermissions(account, fitnessOptions)) {
					MethodChannel.Result result = pendingResult;
					clearPending();
					result.success(buildAuthState());
				} else {
					GoogleSignIn.requestPermissions(this, RC_FIT_PERMISSIONS, account, fitnessOptions);
				}
			} catch (ApiException exception) {
				Log.e(TAG, "Google sign-in failed with code=" + exception.getStatusCode(), exception);
				completePendingWithError("Google sign-in failed.");
			}
			return;
		}

		if (requestCode == RC_FIT_PERMISSIONS) {
			if (pendingResult == null) {
				return;
			}

			GoogleSignInAccount account = GoogleSignIn.getLastSignedInAccount(this);
			if (account != null && GoogleSignIn.hasPermissions(account, fitnessOptions)) {
				MethodChannel.Result result = pendingResult;
				clearPending();
				result.success(buildAuthState());
			} else {
				completePendingWithError("Google Fit permission denied.");
			}
		}
	}

	@Override
	public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
		super.onRequestPermissionsResult(requestCode, permissions, grantResults);

		if (requestCode != RC_RUNTIME_PERMISSIONS || pendingResult == null) {
			return;
		}

		boolean granted = true;
		for (int value : grantResults) {
			if (value != PackageManager.PERMISSION_GRANTED) {
				granted = false;
				break;
			}
		}

		MethodChannel.Result result = pendingResult;
		String action = pendingAction;
		clearPending();

		if (!granted) {
			result.success(buildAuthState());
			return;
		}

		if ("signInInteractive".equals(action)) {
			startSignInFlow(result);
			return;
		}

		if ("requestFitnessPermissions".equals(action)) {
			requestFitnessPermissions(result);
			return;
		}

		result.success(true);
	}

	private long startOfDayMillis() {
		Calendar calendar = Calendar.getInstance();
		calendar.set(Calendar.HOUR_OF_DAY, 0);
		calendar.set(Calendar.MINUTE, 0);
		calendar.set(Calendar.SECOND, 0);
		calendar.set(Calendar.MILLISECOND, 0);
		return calendar.getTimeInMillis();
	}

	private int extractSteps(@NonNull DataReadResponse response) {
		int totalSteps = 0;
		for (Bucket bucket : response.getBuckets()) {
			for (DataSet dataSet : bucket.getDataSets()) {
				if (dataSet.getDataSource().getType() != DataSource.TYPE_DERIVED) {
					continue;
				}
				for (DataPoint point : dataSet.getDataPoints()) {
					for (Field field : point.getDataType().getFields()) {
						if (Field.FIELD_STEPS.equals(field)) {
							totalSteps += point.getValue(field).asInt();
						}
					}
				}
			}
		}

		if (totalSteps > 0) {
			return totalSteps;
		}

		// Fallback for devices where aggregate buckets return non-derived sets.
		for (DataSet dataSet : response.getDataSets()) {
			for (DataPoint point : dataSet.getDataPoints()) {
				for (Field field : point.getDataType().getFields()) {
					if (Field.FIELD_STEPS.equals(field)) {
						totalSteps += point.getValue(field).asInt();
					}
				}
			}
		}
		return totalSteps;
	}

	private int extractHeartRate(@NonNull DataReadResponse response) {
		double sum = 0;
		int count = 0;

		for (Bucket bucket : response.getBuckets()) {
			for (DataSet dataSet : bucket.getDataSets()) {
				if (dataSet.getDataSource().getType() != DataSource.TYPE_DERIVED) {
					continue;
				}
				for (DataPoint point : dataSet.getDataPoints()) {
					if (point.getDataType().getFields().contains(Field.FIELD_AVERAGE)) {
						sum += point.getValue(Field.FIELD_AVERAGE).asFloat();
						count++;
					} else if (point.getDataType().getFields().contains(Field.FIELD_BPM)) {
						sum += point.getValue(Field.FIELD_BPM).asFloat();
						count++;
					}
				}
			}
		}

		if (count == 0) {
			for (DataSet dataSet : response.getDataSets()) {
				for (DataPoint point : dataSet.getDataPoints()) {
					if (point.getDataType().getFields().contains(Field.FIELD_AVERAGE)) {
						sum += point.getValue(Field.FIELD_AVERAGE).asFloat();
						count++;
					} else if (point.getDataType().getFields().contains(Field.FIELD_BPM)) {
						sum += point.getValue(Field.FIELD_BPM).asFloat();
						count++;
					}
				}
			}
		}

		if (count == 0) {
			return 0;
		}
		return (int) Math.round(sum / count);
	}

	private Map<String, Object> buildAuthState() {
		GoogleSignInAccount account = GoogleSignIn.getLastSignedInAccount(this);

		Map<String, Object> state = new HashMap<>();
		state.put("isSignedIn", account != null);
		state.put("displayName", account != null && account.getDisplayName() != null ? account.getDisplayName() : "");
		state.put("fitPermissionGranted", account != null && GoogleSignIn.hasPermissions(account, fitnessOptions));
		state.put("runtimePermissionGranted", hasRuntimePermissions());
		state.put("apiKeyConfigured", !BuildConfig.API_KEY.isEmpty());
		return state;
	}

	private Map<String, Object> buildAuthStateWithMessage(@NonNull String message) {
		Map<String, Object> state = buildAuthState();
		state.put("message", message);
		return state;
	}

	private Map<String, Object> buildErrorMetrics(String message) {
		Map<String, Object> payload = new HashMap<>();
		payload.put("steps", 0);
		payload.put("heartRate", 0);
		payload.put("timestamp", System.currentTimeMillis());
		payload.put("permissionDenied", true);
		payload.put("message", message == null ? "Unable to read Google Fit data." : message);
		return payload;
	}

	private boolean hasRuntimePermissions() {
		List<String> required = new ArrayList<>();
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
			required.add(Manifest.permission.ACTIVITY_RECOGNITION);
		}
		required.add(Manifest.permission.BODY_SENSORS);

		for (String permission : required) {
			if (ContextCompat.checkSelfPermission(this, permission) != PackageManager.PERMISSION_GRANTED) {
				return false;
			}
		}
		return true;
	}

	private void requestRuntimePermissions(@NonNull String action, @NonNull MethodChannel.Result result) {
		List<String> required = new ArrayList<>();
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q
				&& ContextCompat.checkSelfPermission(this, Manifest.permission.ACTIVITY_RECOGNITION)
				!= PackageManager.PERMISSION_GRANTED) {
			required.add(Manifest.permission.ACTIVITY_RECOGNITION);
		}

		if (ContextCompat.checkSelfPermission(this, Manifest.permission.BODY_SENSORS)
				!= PackageManager.PERMISSION_GRANTED) {
			required.add(Manifest.permission.BODY_SENSORS);
		}

		if (required.isEmpty()) {
			result.success(true);
			return;
		}

		if (pendingResult != null) {
			result.error("PENDING", "Another runtime permission request is already running.", null);
			return;
		}

		pendingResult = result;
		pendingAction = action;
		ActivityCompat.requestPermissions(this, required.toArray(new String[0]), RC_RUNTIME_PERMISSIONS);
	}

	private void completePendingWithError(@NonNull String message) {
		if (pendingResult == null) {
			return;
		}
		MethodChannel.Result result = pendingResult;
		clearPending();
		result.success(buildAuthStateWithMessage(message));
	}

	private void clearPending() {
		pendingResult = null;
		pendingAction = null;
	}
}
