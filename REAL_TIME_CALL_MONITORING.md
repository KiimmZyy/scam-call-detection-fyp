# Real-Time Call Monitoring & Scam Detection

## Overview
Your scam detector app now has **real-time call monitoring** capabilities! This feature automatically:
- ✅ Detects when you receive or make calls
- ✅ Records calls in the background
- ✅ Analyzes audio every 5 seconds for scam indicators
- ✅ Shows instant warnings if a scam is detected during the call
- ✅ Saves complete analysis to history after call ends

## How It Works

### 1. **Call Detection**
When a call starts (incoming or outgoing), the app:
- Listens to phone state changes using `phone_state` package
- Automatically starts recording the call
- Shows a notification: "Recording call..."

### 2. **Real-Time Analysis** (Every 5 seconds)
While the call is active:
- Temporarily stops recording
- Sends the audio chunk to your backend API
- Analyzes for scam indicators
- If scam detected → **Shows urgent warning overlay**
- Resumes recording immediately

### 3. **Scam Alert System**
When a scam is detected during a live call:
- 🔴 **Red notification** with scam warning
- 📳 **Vibration alert**
- 🔊 **Sound notification**
- ⚠️ **Overlay popup** showing confidence level
- Example: "⚠️ POSSIBLE SCAM DETECTED! Confidence: 87.5%"

### 4. **Post-Call Processing**
After the call ends:
- Final complete audio analysis
- Saves to call history database
- Shows summary notification:
  - "⚠️ Scam Call Detected" (if scam)
  - "✓ Call Verified Safe" (if not scam)

## User Interface

### Toggle Button
On the home screen, you'll see:
```
[Shield Icon] Real-time Protection     [Switch]
              Active/Inactive
```

**When Enabled (Green)**:
- Shield icon filled
- "Active" status in green
- Automatically monitors ALL calls

**When Disabled (Gray)**:
- Shield icon outline only
- "Inactive" status in gray
- Manual recording only (tap mic button)

## Permissions Required

The app needs these permissions (already added):
1. ✅ `READ_PHONE_STATE` - Detect when calls start/end
2. ✅ `READ_CALL_LOG` - Access call information
3. ✅ `PROCESS_OUTGOING_CALLS` - Monitor outgoing calls
4. ✅ `RECORD_AUDIO` - Record call audio
5. ✅ `FOREGROUND_SERVICE` - Run background service
6. ✅ `SYSTEM_ALERT_WINDOW` - Show overlay warnings during calls
7. ✅ `VIBRATE` - Vibration alerts
8. ✅ `INTERNET` - Send audio to backend API

**First-time setup**: When you toggle "Real-time Protection" ON, the app will request these permissions.

## Technical Implementation

### Files Created/Modified

#### 1. `lib/services/call_monitor_service.dart` (NEW)
- **CallMonitorService** class (Singleton pattern)
- Monitors phone state changes
- Manages recording lifecycle
- Handles periodic analysis
- Shows notifications and overlays
- Saves results to database

#### 2. `lib/screens/home.dart` (UPDATED)
- Added call monitoring toggle switch
- Real-time protection status indicator
- Integration with CallMonitorService
- Overlay support for instant notifications

#### 3. `lib/main.dart` (UPDATED)
- Wrapped app with `OverlaySupport.global`
- Enables overlay notifications

#### 4. `android/app/src/main/AndroidManifest.xml` (UPDATED)
- Added 11 permissions for call monitoring
- Declared foreground service
- Declared broadcast receiver

### Packages Added
```yaml
phone_state: ^3.0.1              # Monitor call state
flutter_local_notifications: ^19.5.0  # System notifications
flutter_foreground_task: ^9.2.0  # Background service
overlay_support: ^2.1.0          # Overlay alerts
permission_handler: ^12.0.1      # Runtime permissions
```

## Usage Instructions

### Enable Real-Time Protection
1. Open the app
2. Go to the home screen (middle tab)
3. Toggle "Real-time Protection" to **ON**
4. Grant all requested permissions
5. You'll see a notification: "Scam Detector Active"

### During a Call
- The app works **automatically** in the background
- You'll see "Recording call..." notification
- If scam detected → Red warning overlay appears
- Continue your call normally (or hang up if suspicious!)

### After a Call
- Notification shows final result
- Check "History" tab to see detailed analysis
- View transcript and confidence score

### Disable Real-Time Protection
1. Toggle "Real-time Protection" to **OFF**
2. You'll see: "Scam Detector Stopped"
3. App returns to manual recording mode

## Important Notes

### ⚠️ Backend API Required
For scam detection to work, your backend API must be running:
```bash
cd backend_api
python app.py
```
The app sends audio to: `http://YOUR_API_URL/detect`

### 🔧 API Configuration
Update the API URL in `lib/providers/api_provider.dart`:
```dart
final String baseUrl = 'http://YOUR_BACKEND_IP:5000';
```

### 📱 Android Version Compatibility
- **Recommended**: Android 10+ (API 29+)
- **Minimum**: Android 6.0 (API 23)
- Some manufacturers (Samsung, Xiaomi) may have additional call recording restrictions

### 🎯 Real-Time vs Manual Mode

**Real-Time Mode** (Toggle ON):
- Automatic call detection
- Background recording
- Live scam detection
- No user interaction needed

**Manual Mode** (Toggle OFF):
- Tap mic button to record
- User controls start/stop
- Analysis after recording stops
- Useful for testing specific audio

## Testing

### Test Real-Time Monitoring
1. Enable "Real-time Protection"
2. Make a test call (or ask someone to call you)
3. Check notifications panel
4. Should see: "Recording call..."
5. After 5 seconds: First analysis runs
6. After call ends: Final result notification

### Test Scam Detection
1. Record or play a scam-like conversation
2. Watch for red warning overlay
3. Check confidence percentage
4. Review in History tab

### Troubleshooting

**"Failed to start recording"**
- Check microphone permission
- Restart the app
- Check Android version compatibility

**"No scam detection results"**
- Ensure backend API is running
- Check API URL configuration
- Verify internet connection
- Check backend logs for errors

**"Permission denied"**
- Go to Settings → Apps → Scam Detector → Permissions
- Enable all required permissions
- Restart the app

**"Recording not starting during calls"**
- Some Android versions restrict call recording
- Check manufacturer-specific restrictions
- Try enabling "Accessibility" permissions

## Future Enhancements

### Possible Improvements
- [ ] WebSocket for real-time streaming (instead of 5-second chunks)
- [ ] Offline mode with on-device AI model
- [ ] Cloud storage for call recordings
- [ ] Advanced statistics (scam patterns, time-based analysis)
- [ ] Customizable alert sounds
- [ ] Whitelist/blacklist phone numbers
- [ ] Integration with caller ID databases

## Privacy & Security

### Data Handling
- Audio recordings stored locally in app's private directory
- Only sent to YOUR backend API
- No third-party data sharing
- User controls when monitoring is active

### User Control
- Toggle protection ON/OFF anytime
- Delete call history entries
- View all analyzed calls
- Clear recordings from storage

## Legal Considerations

⚠️ **Important**: Check local laws regarding call recording:
- Some regions require **two-party consent**
- Commercial use may have additional restrictions
- Always inform call participants if required by law
- This app is for personal protection/research purposes

## Summary

You now have a **complete real-time scam detection system**! 🎉

**Key Features**:
- ✅ Automatic call monitoring
- ✅ Live scam detection during calls
- ✅ Instant warnings with overlays
- ✅ Complete call history
- ✅ Toggle ON/OFF control
- ✅ Professional UI with status indicators

**Next Steps**:
1. Test with real calls
2. Fine-tune detection sensitivity in backend
3. Add more scam keywords/patterns
4. Improve ML model accuracy
5. Consider adding WhatsApp/Telegram call support

Enjoy your enhanced scam protection! 🛡️
