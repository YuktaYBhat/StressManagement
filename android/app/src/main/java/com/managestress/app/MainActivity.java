package com.managestress.app;

import android.Manifest;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
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
import com.google.android.gms.fitness.data.DataSet;
import com.google.android.gms.fitness.data.DataSource;
import com.google.android.gms.fitness.data.DataType;
import com.google.android.gms.fitness.data.Field;
import com.google.android.gms.fitness.request.DataReadRequest;
import com.google.android.gms.fitness.result.DataReadResponse;
import com.google.android.gms.tasks.Task;
import com.google.android.gms.tasks.Tasks;

import java.util.Calendar;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;

import io.flutter.embedding.android.FlutterFragmentActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterFragmentActivity {
	private static final String CHANNEL = "stress_sense/google_fit";
	private static final String TAG = "StressSenseAuth";
	private static final int RC_FIT_PERMISSIONS = 7002;

	private enum PendingFlow {
		NONE,
		SIGN_IN,
		REQUEST_FITNESS_PERMISSIONS,
		FETCH_LIVE_METRICS
	}

	private GoogleSignInClient googleSignInClient;
	private FitnessOptions fitnessOptions;
	private MethodChannel.Result pendingResult;
	private PendingFlow pendingFlow = PendingFlow.NONE;
	private ActivityResultLauncher<Intent> signInLauncher;
	private ActivityResultLauncher<String[]> runtimePermissionsLauncher;

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		initializeGoogleClients();
		registerLaunchers();
	}

	@Override
	public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
		super.configureFlutterEngine(flutterEngine);
		new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL).setMethodCallHandler(this::handleMethodCall);
	}

	private void initializeGoogleClients() {
		GoogleSignInOptions signInOptions = new GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
				.requestEmail()
				.build();
		googleSignInClient = GoogleSignIn.getClient(this, signInOptions);

		fitnessOptions = FitnessOptions.builder()
				.addDataType(DataType.TYPE_HEART_RATE_BPM, FitnessOptions.ACCESS_READ)
				.addDataType(DataType.TYPE_STEP_COUNT_DELTA, FitnessOptions.ACCESS_READ)
				.build();
	}

	private void registerLaunchers() {
		signInLauncher = registerForActivityResult(
				new ActivityResultContracts.StartActivityForResult(),
				result -> handleSignInResult(result.getResultCode(), result.getData())
		);

		runtimePermissionsLauncher = registerForActivityResult(
				new ActivityResultContracts.RequestMultiplePermissions(),
				permissions -> handleRuntimePermissionsResult(permissions)
		);
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
		Log.d(TAG, "Starting Google sign-in flow.");

		if (!ensureRuntimePermissionsOrQueue(PendingFlow.SIGN_IN, result)) {
			return;
		}

		launchGoogleSignIn(result);
	}

	private void requestFitnessPermissions(@NonNull MethodChannel.Result result) {
		GoogleSignInAccount account = getSignedInAccount();
		if (account == null) {
			result.success(buildAuthStateWithMessage("Please sign in with Google first."));
			return;
		}

		if (!ensureRuntimePermissionsOrQueue(PendingFlow.REQUEST_FITNESS_PERMISSIONS, result)) {
			return;
		}

		requestGoogleFitPermissions(account, result, PendingFlow.REQUEST_FITNESS_PERMISSIONS);
	}

	private void fetchLiveMetrics(@NonNull MethodChannel.Result result) {
		GoogleSignInAccount account = getSignedInAccount();
		if (account == null) {
			result.success(buildErrorMetrics("User is not signed in with Google."));
			return;
		}

		if (!ensureRuntimePermissionsOrQueue(PendingFlow.FETCH_LIVE_METRICS, result)) {
			return;
		}

		if (!hasFitPermissions(account)) {
			requestGoogleFitPermissions(account, result, PendingFlow.FETCH_LIVE_METRICS);
			return;
		}

		readLiveMetrics(result);
	}

	private boolean ensureRuntimePermissionsOrQueue(@NonNull PendingFlow flow, @NonNull MethodChannel.Result result) {
		if (hasRuntimePermissions()) {
			return true;
		}

		if (pendingResult != null) {
			result.error("PENDING", "Another permission request is already running.", null);
			return false;
		}

		pendingResult = result;
		pendingFlow = flow;
		runtimePermissionsLauncher.launch(requiredRuntimePermissions());
		return false;
	}

	private void handleRuntimePermissionsResult(@NonNull Map<String, Boolean> permissions) {
		if (pendingResult == null) {
			return;
		}

		boolean granted = true;
		for (String permission : requiredRuntimePermissions()) {
			Boolean allowed = permissions.get(permission);
			if (!Boolean.TRUE.equals(allowed)) {
				granted = false;
				break;
			}
		}

		MethodChannel.Result result = pendingResult;
		PendingFlow flow = pendingFlow;
		clearPending();

		if (!granted) {
			result.success(buildAuthStateWithMessage("Runtime permissions were denied."));
			return;
		}

		switch (flow) {
			case SIGN_IN:
				launchGoogleSignIn(result);
				break;
			case REQUEST_FITNESS_PERMISSIONS:
				requestFitnessPermissions(result);
				break;
			case FETCH_LIVE_METRICS:
				fetchLiveMetrics(result);
				break;
			default:
				result.success(buildAuthState());
				break;
		}
	}

	private void launchGoogleSignIn(@NonNull MethodChannel.Result result) {
		if (googleSignInClient == null) {
			result.success(buildAuthStateWithMessage("Google Sign-In client was not initialized."));
			return;
		}

		if (pendingResult != null) {
			result.error("PENDING", "Another sign-in operation is already running.", null);
			return;
		}

		pendingResult = result;
		pendingFlow = PendingFlow.SIGN_IN;
		signInLauncher.launch(googleSignInClient.getSignInIntent());
	}

	private void handleSignInResult(int resultCode, @Nullable Intent data) {
		if (pendingResult == null || pendingFlow != PendingFlow.SIGN_IN) {
			return;
		}

		if (resultCode != RESULT_OK || data == null) {
			completePendingWithError("Sign-in was cancelled.");
			return;
		}

		try {
			GoogleSignInAccount account = GoogleSignIn.getSignedInAccountFromIntent(data).getResult(ApiException.class);
			if (account == null) {
				completePendingWithError("Google sign-in did not return an account.");
				return;
			}

			if (hasFitPermissions(account)) {
				MethodChannel.Result result = pendingResult;
				clearPending();
				result.success(buildAuthState());
				return;
			}

			requestGoogleFitPermissions(account, pendingResult, PendingFlow.SIGN_IN);
		} catch (ApiException exception) {
			Log.e(TAG, "Google sign-in failed with code=" + exception.getStatusCode(), exception);
			completePendingWithError("Google sign-in failed.");
		}
	}

	@SuppressWarnings("deprecation")
	@Override
	protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
		super.onActivityResult(requestCode, resultCode, data);

		if (requestCode != RC_FIT_PERMISSIONS || pendingResult == null) {
			return;
		}

		GoogleSignInAccount account = getSignedInAccount();
		if (account != null && hasFitPermissions(account)) {
			MethodChannel.Result result = pendingResult;
			PendingFlow flow = pendingFlow;
			clearPending();

			switch (flow) {
				case REQUEST_FITNESS_PERMISSIONS:
				case SIGN_IN:
					result.success(buildAuthState());
					break;
				case FETCH_LIVE_METRICS:
					readLiveMetrics(result);
					break;
				default:
					result.success(buildAuthState());
					break;
			}
			return;
		}

		completePendingWithError("Google Fit permission denied.");
	}

	private void requestGoogleFitPermissions(
			@NonNull GoogleSignInAccount account,
			@NonNull MethodChannel.Result result,
			@NonNull PendingFlow flow
	) {
		if (hasFitPermissions(account)) {
			if (flow == PendingFlow.FETCH_LIVE_METRICS) {
				readLiveMetrics(result);
			} else {
				result.success(buildAuthState());
			}
			return;
		}

		if (pendingResult != null && pendingResult != result) {
			result.error("PENDING", "Another permission operation is already running.", null);
			return;
		}

		pendingResult = result;
		pendingFlow = flow;
		GoogleSignIn.requestPermissions(this, RC_FIT_PERMISSIONS, account, fitnessOptions);
	}

	private void readLiveMetrics(@NonNull MethodChannel.Result result) {
		GoogleSignInAccount account = getSignedInAccount();
		if (account == null || !hasFitPermissions(account)) {
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

					Map<String, Object> payload = new LinkedHashMap<>();
					payload.put("steps", extractSteps(stepsResponse));
					payload.put("heartRate", extractHeartRate(heartResponse));
					payload.put("timestamp", System.currentTimeMillis());
					payload.put("permissionDenied", false);
					result.success(payload);
				})
				.addOnFailureListener(error -> result.success(buildErrorMetrics(error.getMessage())));
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
		GoogleSignInAccount account = getSignedInAccount();

		Map<String, Object> state = new HashMap<>();
		state.put("isSignedIn", account != null);
		state.put("displayName", account != null && account.getDisplayName() != null ? account.getDisplayName() : "");
		state.put("fitPermissionGranted", hasFitPermissions(account));
		state.put("runtimePermissionGranted", hasRuntimePermissions());
		state.put("apiKeyConfigured", isApiKeyConfigured());
		return state;
	}

	private Map<String, Object> buildAuthStateWithMessage(@NonNull String message) {
		Map<String, Object> state = buildAuthState();
		state.put("message", message);
		return state;
	}

	private Map<String, Object> buildErrorMetrics(@Nullable String message) {
		Map<String, Object> payload = new HashMap<>();
		payload.put("steps", 0);
		payload.put("heartRate", 0);
		payload.put("timestamp", System.currentTimeMillis());
		payload.put("permissionDenied", true);
		payload.put("message", message == null || message.isEmpty() ? "Unable to read Google Fit data." : message);
		return payload;
	}

	private boolean hasRuntimePermissions() {
		for (String permission : requiredRuntimePermissions()) {
			if (ContextCompat.checkSelfPermission(this, permission) != PackageManager.PERMISSION_GRANTED) {
				return false;
			}
		}
		return true;
	}

	private boolean hasFitPermissions(@Nullable GoogleSignInAccount account) {
		return account != null && GoogleSignIn.hasPermissions(account, fitnessOptions);
	}

	@Nullable
	private GoogleSignInAccount getSignedInAccount() {
		return GoogleSignIn.getLastSignedInAccount(this);
	}

	private String[] requiredRuntimePermissions() {
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
			return new String[] { Manifest.permission.ACTIVITY_RECOGNITION, Manifest.permission.BODY_SENSORS };
		}
		return new String[] { Manifest.permission.BODY_SENSORS };
	}

	private boolean isApiKeyConfigured() {
		return BuildConfig.API_KEY != null && !BuildConfig.API_KEY.isEmpty();
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
		pendingFlow = PendingFlow.NONE;
	}
}
