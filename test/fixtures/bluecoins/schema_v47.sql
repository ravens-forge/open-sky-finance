-- Bluecoins backup schema (PRAGMA user_version 47), table definitions only.
-- Tests build a synthetic .fydb from this file and sample_data.sql.
CREATE TABLE `ACCOUNTINGGROUPTABLE` (`accountingGroupTableID` INTEGER PRIMARY KEY AUTOINCREMENT, `accountGroupName` TEXT);
CREATE TABLE `ACCOUNTTYPETABLE` (`accountTypeTableID` INTEGER PRIMARY KEY AUTOINCREMENT, `accountTypeName` TEXT, `accountingGroupID` INTEGER);
CREATE TABLE `ACCOUNTSTABLE` (`accountsTableID` INTEGER, `accountName` TEXT, `accountTypeID` INTEGER, `accountHidden` INTEGER, `accountCurrency` TEXT, `accountConversionRateNew` REAL, `creditLimit` INTEGER, `cutOffDa` INTEGER, `creditCardDueDate` INTEGER, `cashBasedAccounts` INTEGER, `accountSelectorVisibility` INTEGER, `currencyChanged` INTEGER, `accountsExtraColumnInt1` INTEGER, `accountsExtraColumnInt2` INTEGER, `accountsExtraColumnString1` TEXT, `accountsExtraColumnString2` TEXT, PRIMARY KEY(`accountsTableID`));
CREATE TABLE `CATEGORYGROUPTABLE` (`categoryGroupTableID` INTEGER PRIMARY KEY AUTOINCREMENT, `categoryGroupName` TEXT);
CREATE TABLE `PARENTCATEGORYTABLE` (`parentCategoryTableID` INTEGER, `parentCategoryName` TEXT, `budgetAmountCategoryParent` INTEGER, `budgetEnabledCategoryParent` INTEGER, `categoryGroupID` INTEGER, `budgetPeriodCategoryParent` INTEGER, `budgetCustomSetupParent` TEXT, `categoryParentExtraColumnInt1` INTEGER, `categoryParentExtraColumnInt2` INTEGER, `categoryParentExtraColumnString1` TEXT, `categoryParentExtraColumnString2` TEXT, PRIMARY KEY(`parentCategoryTableID`));
CREATE TABLE `CHILDCATEGORYTABLE` (`categoryTableID` INTEGER PRIMARY KEY AUTOINCREMENT, `childCategoryName` TEXT, `budgetAmount` INTEGER, `budgetCustomSetup` TEXT, `budgetEnabledCategoryChild` INTEGER, `budgetPeriod` INTEGER, `childCategoryIcon` TEXT, `categorySelectorVisibility` INTEGER, `parentCategoryID` INTEGER, `categoryExtraColumnInt1` INTEGER, `categoryExtraColumnInt2` INTEGER, `categoryExtraColumnString1` TEXT, `categoryExtraColumnString2` TEXT);
CREATE TABLE `ITEMTABLE` (`itemTableID` INTEGER PRIMARY KEY AUTOINCREMENT, `itemName` TEXT, `itemAutoFillVisibility` INTEGER);
CREATE TABLE `LABELSTABLE` (`labelsTableID` INTEGER PRIMARY KEY AUTOINCREMENT, `labelName` TEXT, `transactionIDLabels` INTEGER);
CREATE TABLE `TRANSACTIONTYPETABLE` (`transactionTypeTableID` INTEGER PRIMARY KEY AUTOINCREMENT, `transactionTypeName` TEXT);
CREATE TABLE `TRANSACTIONSTABLE` (`transactionsTableID` INTEGER, `itemID` INTEGER, `uidPairID` INTEGER, `amount` INTEGER, `transactionCurrency` TEXT, `conversionRateNew` REAL, `date` TEXT, `transactionTypeID` INTEGER, `categoryID` INTEGER, `accountID` INTEGER, `accountPairID` INTEGER, `notes` TEXT, `status` INTEGER, `accountReference` INTEGER, `deletedTransaction` INTEGER, `newSplitTransactionID` INTEGER, `transferGroupID` INTEGER, `reminderTransaction` INTEGER, `reminderGroupID` INTEGER, `reminderFrequency` INTEGER, `reminderRepeatEvery` INTEGER, `reminderEndingType` INTEGER, `reminderStartDate` TEXT, `reminderEndDate` TEXT, `reminderAfterNoOfOccurences` INTEGER, `reminderAutomaticLogTransaction` INTEGER, `reminderRepeatByDayOfMonth` INTEGER, `reminderExcludeWeekend` INTEGER, `reminderWeekDayMoveSetting` INTEGER, `reminderUnbilled` INTEGER, `creditCardInstallment` INTEGER, `reminderVersion` INTEGER, `dataExtraColumnString1` TEXT, PRIMARY KEY(`transactionsTableID`));
CREATE TABLE `SETTINGSTABLE` (`settingsTableID` INTEGER PRIMARY KEY AUTOINCREMENT, `defaultSettings` TEXT);
CREATE TABLE `PICTURETABLE` (`pictureTableID` INTEGER PRIMARY KEY AUTOINCREMENT, `pictureFileName` TEXT, `transactionID` INTEGER);
CREATE TABLE `FILTERSTABLE` (`filtersTableID` INTEGER PRIMARY KEY AUTOINCREMENT, `filtername` TEXT, `filterJSON` TEXT);
CREATE TABLE `NOTIFICATIONTABLE` (`smsTableID` INTEGER PRIMARY KEY AUTOINCREMENT, `notificationPackageName` TEXT, `notificationAppName` TEXT, `notificationDefaultName` TEXT, `notificationSenderAccountID` INTEGER, `notificationSenderCategoryID` INTEGER, `notificationSenderAmountOrder` INTEGER);
CREATE TABLE `SMSSTABLE` (`smsTableID` INTEGER PRIMARY KEY AUTOINCREMENT, `senderName` TEXT, `senderDefaultName` TEXT, `senderAccountID` INTEGER, `senderCategoryID` INTEGER, `senderAmountOrder` INTEGER);
CREATE TABLE android_metadata (locale TEXT);
CREATE TABLE room_master_table (id INTEGER PRIMARY KEY,identity_hash TEXT);

CREATE INDEX `accountsTable1` ON `ACCOUNTSTABLE` (`accountTypeID`);
CREATE INDEX `accountsTypeTable1` ON `ACCOUNTTYPETABLE` (`accountingGroupID`);
CREATE INDEX `categoryChildTable1` ON `CHILDCATEGORYTABLE` (`parentCategoryID`);
CREATE INDEX `categoryParentTable1` ON `PARENTCATEGORYTABLE` (`categoryGroupID`);
CREATE INDEX `transactionsTable1` ON `TRANSACTIONSTABLE` (`accountID`);
CREATE INDEX `transactionsTable2` ON `TRANSACTIONSTABLE` (`categoryID`);

PRAGMA user_version = 47;
