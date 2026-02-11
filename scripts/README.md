# Firebase Import Scripts

## Prerequisites

### 1. Download Service Account Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **marketcoach-db8f4**
3. Click the gear icon ⚙️ > **Project Settings**
4. Go to **Service Accounts** tab
5. Click **Generate New Private Key**
6. Save the downloaded file as `serviceAccountKey.json` in the project root:
   ```
   C:\FinancialApplication\market_coach\serviceAccountKey.json
   ```

⚠️ **Important**: Add `serviceAccountKey.json` to `.gitignore` to keep your credentials safe!

## Import Lessons

### Import RSI Lesson
```bash
npm run import-lessons
```

### Import Custom Lesson File
```bash
node scripts/import_lessons.js path/to/your/lesson.json
```

## What Gets Imported

The script imports:
- Lesson document to `lessons/{lessonId}`
- All screens to `lessons/{lessonId}/screens/{screenId}`
- Converts `published_at` strings to Firestore timestamps

## Troubleshooting

**Error: serviceAccountKey.json not found**
- Make sure you downloaded the service account key from Firebase Console
- Save it in the project root (not in the scripts folder)

**Permission denied**
- Verify the service account has Firestore write permissions
- Check that you selected the correct Firebase project
