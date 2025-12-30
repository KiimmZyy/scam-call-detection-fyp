# Testing Real-Time Call Monitoring

## ✅ App Successfully Running!

The app has been deployed to your Android emulator with the new real-time call monitoring feature.

## What's New on the Home Screen

You should see:
1. **Real-time Protection Toggle** at the top
   - Shield icon (🛡️)
   - "Active" or "Inactive" status
   - Green when enabled, gray when disabled

## Testing Steps

### 1. Enable Real-Time Protection
1. **Tap the toggle switch** on the home screen
2. **Grant permissions** when prompted:
   - Phone permissions
   - Microphone
   - Storage
   - Notifications
   - Overlay permissions
3. You should see a **green notification**: "Real-time call protection enabled"
4. The shield icon should turn **solid green**

### 2. Testing With Emulator Calls

#### Making a Test Call (Emulator):
```bash
# Method 1: Using adb
adb shell am start -a android.intent.action.CALL -d tel:+1234567890

# Method 2: Using emulator controls
1. Open emulator's Extended Controls (... button)
2. Go to "Phone" section
3. Enter a phone number
4. Click "Call Device"
```

#### Simulating Incoming Call:
```bash
# Use telnet to control emulator
telnet localhost 5554
gsm call +1234567890
# To end the call:
gsm cancel +1234567890
```

### 3. What to Expect

**When Call Starts**:
- Notification: "Recording call..."
- Purple overlay popup appears

**During Call** (Every 5 seconds):
- Audio chunk sent to backend for analysis
- If scam detected → **Red warning overlay**
- If safe → Continues silently

**When Call Ends**:
- Final analysis complete
- Notification shows result:
  - "⚠️ Scam Call Detected" OR
  - "✓ Call Verified Safe"
- Call saved to History tab

### 4. Check History
1. Tap **History tab** (left icon)
2. You should see the recorded call
3. Tap on it to see:
   - Phone number
   - Transcript
   - Confidence score
   - Scam/Safe status

## Important Notes

### ⚠️ Backend API Requirement
For scam detection to actually work, you MUST:
1. Start your backend API server
2. Update API URL in code

**Currently the API URL is set to localhost which won't work on emulator!**

#### To Fix API Connection:
1. Find your computer's local IP:
   ```bash
   ipconfig
   # Look for IPv4 Address (e.g., 192.168.1.5)
   ```

2. Update [lib/providers/api_provider.dart](lib/providers/api_provider.dart):
   ```dart
   final String baseUrl = 'http://YOUR_IP_ADDRESS:5000';
   // Example: 'http://192.168.1.5:5000'
   ```

3. Start backend:
   ```bash
   cd backend_api
   python app.py
   ```

### Testing Without Backend
If backend isn't running:
- App will still record calls
- No scam detection will occur
- You'll see errors in logs
- Calls won't be saved to history

### Real Device Testing
For best results, test on a **real Android device**:
1. Connect phone via USB
2. Enable USB debugging
3. Run: `flutter run`
4. Make real phone calls
5. See actual real-time scam detection!

## Troubleshooting

### "Failed to start recording"
- Check microphone permission
- Restart the app

### "No notifications appearing"
- Check notification permissions
- Enable "Do Not Disturb" exceptions

### "Toggle doesn't work"
- Check logs for permission errors
- Grant all requested permissions manually

### "API connection failed"
- Update API URL to your computer's IP
- Start backend server
- Check firewall settings

## Feature Status

✅ **Completed**:
- Real-time call detection
- Automatic recording
- Periodic audio analysis (5-second chunks)
- Scam alert overlays
- History saving
- Toggle on/off control

⚠️ **Needs Backend**:
- Actual scam detection
- Transcript generation
- Confidence scoring

## Next Steps

1. ✅ Enable real-time protection
2. ✅ Grant all permissions
3. ⚠️ Fix backend API connection
4. ✅ Make test calls
5. ✅ Check history

Enjoy your real-time scam detection! 🛡️
