-- Invented data for a synthetic Bluecoins backup: round amounts in micro-units,
-- fixed dates, no real person. Reference names are in Spanish on purpose, since
-- the importer must match by id only.
-- Expected result as of 2026-09-17 (see test/services/bluecoins_import_test.dart).

INSERT INTO android_metadata (locale) VALUES ('es_ES');
INSERT INTO room_master_table (id, identity_hash) VALUES (42, 'be183e46451dc3214c731b0649d935a4');

INSERT INTO ACCOUNTINGGROUPTABLE (accountingGroupTableID, accountGroupName) VALUES
  (1, 'Activos'), (2, 'Pasivos');

INSERT INTO ACCOUNTTYPETABLE (accountTypeTableID, accountTypeName, accountingGroupID) VALUES
  (1, 'Otros activos', 1), (2, 'Otros pasivos', 2), (3, 'Banco', 1), (4, 'Efectivo', 1),
  (5, 'Inversiones', 1), (6, 'Por cobrar', 1), (7, 'Propiedades', 1),
  (8, 'Tarjeta de crédito', 2), (9, 'Préstamos', 2), (10, 'Por pagar', 2),
  (11, 'Hipotecas', 2), (12, 'Activos externos', 1), (13, 'Pasivos externos', 2),
  (15, 'Cuentas virtuales', 1), (16, 'Criptomonedas', 1),
  -- Not in the known list: falls back to its accounting group.
  (17, 'Tipo propio', 2);

INSERT INTO CATEGORYGROUPTABLE (categoryGroupTableID, categoryGroupName) VALUES
  (0, 'Ninguno'), (1, 'Transferencia'), (2, 'Ingresos'), (3, 'Gastos');

INSERT INTO TRANSACTIONTYPETABLE (transactionTypeTableID, transactionTypeName) VALUES
  (2, 'Nueva cuenta'), (3, 'Gasto'), (4, 'Ingreso'), (5, 'Transferencia');

INSERT INTO ACCOUNTSTABLE (accountsTableID, accountName, accountTypeID, accountHidden, accountCurrency, accountConversionRateNew, creditLimit) VALUES
  -- System placeholders: skipped.
  (-1, '(Sin cuenta)', 0, 0, 'EUR', 1.0, 0),
  (0, '(Sin cuenta)', 0, 0, 'EUR', 1.0, 0),
  (1, ' Test Bank ', 3, 0, 'EUR', 1.0, 0),
  (2, 'Test Wallet', 4, 0, 'EUR', 1.0, 0),
  (1700000000001, 'Test Card', 8, 0, 'EUR', 1.0, 1500000000),
  (1700000000002, 'Old Savings', 3, 1, 'EUR', 1.0, 0),
  (1700000000003, 'Test Dollars', 3, 0, 'USD', 1.1, 0),
  (1700000000004, 'Custom Debt', 17, 0, 'EUR', 1.0, 0);

INSERT INTO PARENTCATEGORYTABLE (parentCategoryTableID, parentCategoryName, budgetAmountCategoryParent, budgetEnabledCategoryParent, categoryGroupID, budgetPeriodCategoryParent) VALUES
  -- System groups: skipped.
  (0, '(Nueva cuenta)', 0, 0, 0, 0),
  (1, '(Transferencia)', 0, 0, 1, 0),
  (2, 'Salary', 0, 0, 2, 0),
  -- A budget with an unconfirmed period: reported, not imported.
  (3, 'Food', 300000000, 1, 3, 3),
  (4, 'Other', 0, 0, 3, 0),
  -- Same name as the expense group: both are imported.
  (5, 'Other', 0, 0, 2, 0);

INSERT INTO CHILDCATEGORYTABLE (categoryTableID, childCategoryName, budgetAmount, budgetEnabledCategoryChild, budgetPeriod, childCategoryIcon, categorySelectorVisibility, parentCategoryID) VALUES
  (0, '(Nueva cuenta)', 0, 0, 0, 'Outlined.Add', 1, 0),
  (1, '(Transferencia)', 0, 0, 0, 'Outlined.SwapHoriz', 1, 1),
  (2, 'Monthly pay', 0, 0, 0, 'Outlined.Work', 1, 2),
  (3, 'Groceries', 200000000, 1, 0, 'Outlined.LocalGroceryStore', 1, 3),
  (4, 'Fuel', 0, 0, 0, 'Outlined.LocalGasStation', 1, 4),
  -- Not in the app's icon map: default icon.
  (5, 'Misc', 0, 0, 0, 'AutoMirrored.Outlined.List', 1, 4),
  (6, 'Gifts', 0, 0, 0, 'Outlined.CardGiftcard', 1, 5);

INSERT INTO ITEMTABLE (itemTableID, itemName, itemAutoFillVisibility) VALUES
  (1, 'Supermarket', 1), (2, 'Salary', 1), (3, 'Refund', 1), (4, 'To the wallet', 1),
  (5, 'Gas station', 1), (6, 'Lottery', 1), (7, 'Rent', 1), (8, 'To dollars', 1),
  (9, 'Kiosk', 1), (10, 'Bookshop', 1), (11, 'Old transfer', 1);

-- Ordinary rows carry the default reminder values (frequency 0, every 1,
-- ending 1, a start date) with reminderTransaction NULL.
INSERT INTO TRANSACTIONSTABLE (transactionsTableID, itemID, uidPairID, amount, transactionCurrency, conversionRateNew, date, transactionTypeID, categoryID, accountID, accountPairID, notes, status, accountReference, deletedTransaction, newSplitTransactionID, transferGroupID, reminderTransaction, reminderGroupID, reminderFrequency, reminderRepeatEvery, reminderEndingType, reminderStartDate) VALUES
  -- Opening balances; the zero one is skipped.
  (10, NULL, 10, 1000000000, 'EUR', 1.0, '2026-01-01 00:00:00', 2, 0, 1, 1, '', 2, 3, 6, NULL, NULL, NULL, NULL, 0, 1, 1, '2026-01-01 00:00:00'),
  (11, NULL, 11, 0, 'EUR', 1.0, '2026-01-01 00:00:00', 1, 0, 2, 2, '', 2, 3, 6, NULL, NULL, NULL, NULL, 0, 1, 1, '2026-01-01 00:00:00'),
  (12, NULL, 12, -200000000, 'EUR', 1.0, '2026-01-01 00:00:00', 2, 0, 1700000000001, 1700000000001, '', 2, 3, 6, NULL, NULL, NULL, NULL, 0, 1, 1, '2026-01-01 00:00:00'),
  (13, NULL, 13, 500000000, 'EUR', 1.0, '2026-01-01 00:00:00', 2, 0, 1700000000002, 1700000000002, '', 2, 3, 6, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
  (14, NULL, 14, -50000000, 'EUR', 1.0, '2026-01-01 00:00:00', 2, 0, 1700000000004, 1700000000004, '', 2, 3, 6, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
  -- Expense, income and a refund (a positive expense).
  (20, 1, 20, -45500000, 'EUR', 1.0, '2026-01-05 12:30:00', 3, 3, 1, 1, 'Weekly shop', 0, 0, 6, NULL, NULL, NULL, NULL, 0, 1, 1, '2026-01-05 12:30:00'),
  (21, 2, 21, 2000000000, 'EUR', 1.0, '2026-01-31 09:00:00', 4, 2, 1, 1, '', 0, 0, 6, NULL, NULL, NULL, NULL, 0, 1, 1, '2026-01-31 09:00:00'),
  (22, 3, 22, 10000000, 'EUR', 1.0, '2026-02-02 18:00:00', 3, 3, 1, 1, '', 0, 0, 6, NULL, NULL, NULL, NULL, 0, 1, 1, '2026-02-02 18:00:00'),
  -- Transfer, one row per leg.
  (30, 4, 31, -100000000, 'EUR', 1.0, '2026-02-10 10:00:00', 5, 1, 1, 2, 'Cash for the week', 0, 1, 6, NULL, 900, NULL, NULL, 0, 1, 1, '2026-02-10 10:00:00'),
  (31, 4, 30, 100000000, 'EUR', 1.0, '2026-02-10 10:00:00', 5, 1, 2, 1, 'Cash for the week', 0, 2, 6, NULL, 900, NULL, NULL, 0, 1, 1, '2026-02-10 10:00:00'),
  -- Deleted transfer and deleted income.
  (32, 11, 33, -60000000, 'EUR', 1.0, '2026-02-12 10:00:00', 5, 1, 1, 2, '', 0, 1, 5, NULL, 901, NULL, NULL, 0, 1, 1, '2026-02-12 10:00:00'),
  (33, 11, 32, 60000000, 'EUR', 1.0, '2026-02-12 10:00:00', 5, 1, 2, 1, '', 0, 2, 5, NULL, 901, NULL, NULL, 0, 1, 1, '2026-02-12 10:00:00'),
  (34, 6, 34, 50000000, 'EUR', 1.0, '2026-02-14 20:00:00', 4, 6, 2, 2, '', 0, 0, 5, NULL, NULL, NULL, NULL, 0, 1, 1, '2026-02-14 20:00:00'),
  -- Credit card expense, and a future-dated one (scheduled).
  (35, 5, 35, -80000000, 'EUR', 1.0, '2026-03-01 08:15:00', 3, 4, 1700000000001, 1700000000001, '', 0, 0, 6, NULL, NULL, NULL, NULL, 0, 1, 1, '2026-03-01 08:15:00'),
  (36, 5, 36, -30000000, 'EUR', 1.0, '2027-01-15 08:15:00', 3, 4, 1700000000001, 1700000000001, '', 0, 0, 6, NULL, NULL, NULL, NULL, 0, 1, 1, '2027-01-15 08:15:00'),
  -- Transfer between currencies: 90 EUR become 100 USD.
  (37, 8, 38, -90000000, 'EUR', 1.0, '2026-03-10 11:00:00', 5, 1, 1, 1700000000003, '', 0, 1, 6, NULL, 902, NULL, NULL, 0, 1, 1, '2026-03-10 11:00:00'),
  (38, 8, 37, 100000000, 'USD', 1.1, '2026-03-10 11:00:00', 5, 1, 1700000000003, 1, '', 0, 2, 6, NULL, 902, NULL, NULL, 0, 1, 1, '2026-03-10 11:00:00'),
  -- Skipped: a reminder template, an unknown type, an unknown deleted
  -- state, a transfer missing one side, another currency, a placeholder
  -- assets account.
  (40, 7, 40, -700000000, 'EUR', 1.0, '2026-04-01 09:00:00', 3, 4, 1, 1, '', 0, 0, 6, NULL, NULL, 1, 1700000000100, 3, 1, 0, '2026-04-01 09:00:00'),
  (41, NULL, 41, -1000000, 'EUR', 1.0, '2026-04-02 09:00:00', 7, 4, 1, 1, '', 0, 0, 6, NULL, NULL, NULL, NULL, 0, 1, 1, '2026-04-02 09:00:00'),
  (42, NULL, 42, -2000000, 'EUR', 1.0, '2026-04-03 09:00:00', 3, 4, 1, 1, '', 0, 0, 4, NULL, NULL, NULL, NULL, 0, 1, 1, '2026-04-03 09:00:00'),
  (43, NULL, 44, -20000000, 'EUR', 1.0, '2026-04-04 09:00:00', 5, 1, 1, 2, '', 0, 1, 6, NULL, 903, NULL, NULL, 0, 1, 1, '2026-04-04 09:00:00'),
  (45, 1, 45, -12000000, 'GBP', 1.2, '2026-04-05 09:00:00', 3, 3, 1, 1, '', 0, 0, 6, NULL, NULL, NULL, NULL, 0, 1, 1, '2026-04-05 09:00:00'),
  (46, 1, 46, -3000000, 'EUR', 1.0, '2026-04-06 09:00:00', 3, 3, -1, -1, '', 0, 0, 6, NULL, NULL, NULL, NULL, 0, 1, 1, '2026-04-06 09:00:00'),
  -- Imported with a note: a category that does not exist, and a split.
  (47, 9, 47, -5000000, 'EUR', 1.0, '2026-05-01 17:00:00', 3, 99, 2, 2, '', 0, 0, 6, NULL, NULL, NULL, NULL, 0, 1, 1, '2026-05-01 17:00:00'),
  (48, 10, 48, -8000000, 'EUR', 1.0, '2026-05-02 17:00:00', 3, 5, 2, 2, '', 0, 0, 6, 555, NULL, NULL, NULL, 0, 1, 1, '2026-05-02 17:00:00');

-- Definitions (no transaction) and assignments; names repeat with other
-- case and spaces.
INSERT INTO LABELSTABLE (labelsTableID, labelName, transactionIDLabels) VALUES
  (1, 'Holiday', NULL),
  (2, 'Trip', NULL),
  (3, ' holiday', 20),
  (4, 'Weekly', 30),
  (5, 'weekly', 31),
  (6, 'Car', 35),
  (7, 'Gone', 34);

INSERT INTO SETTINGSTABLE (settingsTableID, defaultSettings) VALUES
  (1, 'EUR'), (2, 'es'), (3, '2026-01-01 10:00:00.000'), (7, '1789000000000');
