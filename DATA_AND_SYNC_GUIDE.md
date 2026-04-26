# 📚 The "Zero to Hero" Guide: Offline Sync & Data Flow

This document is written for someone with **zero prior Flutter knowledge** to perfectly understand how data moves from a screen, into our local database, and up to the cloud, especially when the internet disconnects.

---

## 1. The Exact Timeline of a "Save"
When you type "Drink Water" on your screen and hit Save, **when exactly does Firebase get it?** Does it happen at the exact same time as the Dart model? 

**Answer:** No. It is a strict 4-step sequence. Firebase is always the *very last* thing to happen.

1. **Step 1 (The Screen):** The user types data.
2. **Step 2 (The Model):** The Dart code packages that data into a neat box.
3. **Step 3 (SQLite Local DB):** The box is saved to the phone's physical memory **first**. 
4. **Step 4 (Firebase Cloud):** *After* the phone confirms it is saved locally, it sends a copy of the box to the cloud.

### Why do we save to SQLite *before* Firebase?
Because of **Speed** and **Offline Capability**. If we waited for Firebase first, the user's screen would freeze with a loading spinner while waiting for the internet. By saving to SQLite first, the app feels instantly fast, and we can handle the internet backup invisibly in the background.

---

## 2. The Offline Magic: What Happens When the Internet Dies?

### Scenario A: User saves data while offline.
* When the Repository saves the goal to SQLite, it adds a secret hidden tag called `sync_status`. 
* By default, `sync_status = 0` (which means "Not backed up to the cloud yet").
* The app tries to send it to Firebase (Step 4), but because there is no internet, the send fails.
* **Result:** The user doesn't care! The goal is safely stored in SQLite on their phone. They can see it, edit it, and use the app normally. The `sync_status` stays `0`.

### Scenario B: User closes the app, internet returns, user reopens the app.
How does the cloud finally get the data?
* When the user opens the app and logs in, a special script called `SyncService.syncData()` automatically wakes up.
* It looks inside the SQLite database and says: *"Give me every single goal where `sync_status == 0`."*
* It finds all the offline goals the user created yesterday.
* It safely uploads them all to Firebase.
* Once Firebase says "I got them!", the app changes the local SQLite tag to `sync_status = 1` (Backed up!).

---

## 3. How the Files Link Together (The Code Map)

If you have zero knowledge of Flutter, you need to understand how files "talk" to each other. They talk using `import` statements at the top of the file, and by calling functions.

Here is the exact chain of command with the real file paths:

### Link 1: The Screen calls the Repository
**File:** `lib/screens/goals_screen.dart`
**How it links:** At the top of this file, it has `import '../repositories/goal_repository.dart';`
* The UI is just a dumb screen. It has text boxes.
* When you click "Save", it calls a function from the imported file: `GoalRepository().insertGoal(...)`.
* It hands over the data and says, "I don't know how to save this, you do it!"

### Link 2: The Repository calls the Model Translator
**File:** `lib/repositories/goal_repository.dart`
**How it links:** It has `import '../models/goal.dart';`
* The Repository receives the Dart data. But SQLite needs a dictionary (a Map).
* The Repository calls the Model's translator: `goal.toMap()`. 
* *This is the magical link where the Dart data formats itself perfectly.*

### Link 3: The Repository saves to SQLite
**File:** `lib/repositories/goal_repository.dart`
**How it links:** It has `import '../database/database_helper.dart';`
* Now that the data is translated into a Map, the Repository opens the connection to the phone's hard drive.
* It runs: `db.insert('goals', goal.toMap())`.
* The data is now physically on the phone. `sync_status` is `0`.

### Link 4: The Repository calls the Sync Service
**File:** `lib/repositories/goal_repository.dart`
**How it links:** It has `import '../services/sync_service.dart';`
* The local save is done. Now, the Waiter (Repository) calls the Corporate Messenger (Sync Service).
* It runs: `_syncService.syncGoal(goal)`.

### Link 5: The Sync Service talks to Firebase
**File:** `lib/services/sync_service.dart`
**How it links:** It has `import 'package:cloud_firestore/cloud_firestore.dart';`
* This file is the ONLY file that knows Firebase exists.
* It takes the same `goal.toMap()` and fires it through the internet to the cloud: `.set(goal.toMap())`.
* If successful, it tells SQLite: *"Change `sync_status` to 1!"*

---
**Summary for Viva:** 
"My components are strictly linked in a one-way chain: **UI -> Repository -> SQLite -> SyncService -> Firebase**. The UI never talks to the database, and the local database never talks to Firebase. They communicate by passing the `toMap()` data package down the chain. This guarantees that if the internet chain breaks at the very end, the local app chain remains 100% unbreakable."