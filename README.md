# 🛎️ Smart Waiter

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=flat-square&logo=dart)
![Architecture](https://img.shields.io/badge/Architecture-Modular-success?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)

Το **Smart Waiter** είναι ένα προηγμένο, Offline-First Mobile POS (Point of Sale) και σύστημα παραγγελιοληψίας, σχεδιασμένο αποκλειστικά για τον κλάδο της εστίασης. Προσφέρει αστραπιαία ταχύτητα, πλήρη ανεξαρτησία από το internet και P2P συγχρονισμό δεδομένων μέσω τοπικού δικτύου.

## ✨ Βασικά Χαρακτηριστικά (Features)

*   🗺️ **Διαδραστικός Χάρτης (Virtual Canvas):** Ελεύθερη τοποθέτηση τραπεζιών (Drag & Drop) σε καμβά μεγάλων διαστάσεων με Custom Borders ανά χώρο και υποστήριξη Pinch-to-Zoom.
*   🔄 **Drag-to-Merge & Transfer:** Πρωτοποριακό UI όπου η μεταφορά παραγγελίας ή η ένωση (Merge) τραπεζιών γίνεται απλώς σέρνοντας το ένα τραπέζι πάνω στο άλλο.
*   ⚡ **Smart Search:** Έξυπνος αλγόριθμος αναζήτησης (Fuzzy & Phonetic) που αγνοεί ορθογραφικά λάθη, τόνους και Greeklish (π.χ. βρίσκει το "Freddo Espresso" γράφοντας "φρεντο").
*   📡 **P2P Wi-Fi Sync:** Τοπικός HTTP Server ενσωματωμένος στην εφαρμογή. Η "Master" συσκευή μοιράζει το στήσιμο του μαγαζιού (Κατάλογος, Χώροι, Τραπέζια) στις υπόλοιπες συσκευές μέσω QR Code, χωρίς εξωτερικό server.
*   💳 **Έξυπνο Ταμείο:** Υποστήριξη ολικής και μερικής εξόφλησης με επιλογή συγκεκριμένων ποσοτήτων. Premium Dashboard με στατιστικά βάρδιας (Ζ) και ιστορικό συναλλαγών.
*   🔒 **Offline-First:** Όλα τα δεδομένα αποθηκεύονται κρυπτογραφημένα τοπικά (SharedPreferences). Μηδενικός χρόνος αναμονής, μηδενικό server latency.

## 📂 Αρχιτεκτονική Κώδικα

Το project ακολουθεί αυστηρή Modular δομή (Single Responsibility Principle) για μέγιστη αναγνωσιμότητα και ευκολία συντήρησης:
```text
lib/
 ├── models/      # Data Models (Space, Product, TableOrder, ShiftTransaction)
 ├── services/    # Αποθήκευση (StorageService) & Δίκτυο (WifiSyncService)
 ├── utils/       # Core Logic & Αλγόριθμοι (SmartSearchHelper)
 ├── widgets/     # Επαναχρησιμοποιήσιμα UI Components & Canvas Painters
 └── screens/     # Οθόνες (Main, Order, Scanner) & Tabs (FloorPlan, Shift, Setup)
