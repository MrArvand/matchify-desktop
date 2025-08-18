# 🎯 Matchify Desktop - تطبیق فایل‌های مالی

## 📋 Overview - خلاصه

**Matchify Desktop** is a powerful Flutter-based desktop application designed to reconcile payment invoices from accounting software with bank payment receipts. The application intelligently matches transactions using advanced algorithms and provides an intuitive interface for financial reconciliation.

**Matchify Desktop** یک نرم‌افزار قدرتمند مبتنی بر Flutter است که برای تطبیق فاکتورهای پرداخت نرم‌افزار حسابداری با رسیدهای پرداخت بانکی طراحی شده است. این نرم‌افزار با استفاده از الگوریتم‌های پیشرفته، تراکنش‌ها را تطبیق می‌دهد و رابط کاربری ساده‌ای برای تطبیق مالی ارائه می‌دهد.

---

## ✨ Key Features - ویژگی‌های کلیدی

### 🔍 **Intelligent Matching - تطبیق هوشمند**
- **Exact Matches**: One-to-one payment matching using "meet in the middle" algorithm
- **Combination Matches**: Find combinations of multiple bank transactions that sum to a single invoice
- **Terminal Code Support**: Group and match transactions by terminal codes for better accuracy
- **Real-time Conflict Resolution**: Automatically remove conflicting options when selections are made

### 📊 **Advanced Algorithms - الگوریتم‌های پیشرفته**
- **Subset Sum Algorithm**: Efficiently find combinations of up to 10+ transactions
- **Time-budgeted Processing**: Optimized for large datasets with configurable processing limits
- **Combination Deduplication**: Eliminate redundant combinations regardless of order
- **Priority-based Matching**: Terminal-based combinations get highest priority

### 🎨 **User Experience - تجربه کاربری**
- **Persian Language Support**: Full RTL and Persian number formatting
- **Intuitive Badge System**: Clear visual indicators for different combination types
- **Interactive Selection**: Easy-to-use radio buttons for combination selection
- **Real-time Updates**: Dynamic UI updates as selections are made

---

## 🚀 Installation - نصب

### **System Requirements - نیازمندی‌های سیستم**
- **Operating System**: Windows 10/11 (64-bit)
- **RAM**: Minimum 4GB, Recommended 8GB+
- **Storage**: 500MB available space
- **Display**: 1366x768 minimum resolution

### **Installation Steps - مراحل نصب**

1. **Download**: Download the latest installer from the official repository
2. **Run Installer**: Double-click the `.exe` installer file
3. **Follow Setup**: Accept license agreement and choose installation location
4. **Complete Installation**: Wait for installation to complete
5. **Launch Application**: Start Matchify Desktop from Start Menu or Desktop shortcut

---

## 📖 Usage Guide - راهنمای استفاده

### **Step 1: File Upload - آپلود فایل**
1. **Upload Payment File**: Select the Excel file containing payment invoices (Varanegar)
2. **Upload Bank File**: Select the Excel file containing bank payment receipts
3. **Select Amount Columns**: Specify which columns contain the payment amounts
4. **Optional Terminal Code**: If available, select the terminal code column from bank file

### **Step 2: Column Selection - انتخاب ستون‌ها**
- **Payment Amount Column**: Column containing invoice amounts (e.g., "مبلغ دریافت")
- **Bank Amount Column**: Column containing bank transaction amounts (e.g., "مبلغ")
- **Terminal Code Column**: Optional column for grouping transactions by terminal

### **Step 3: Processing - پردازش**
- The application automatically processes files and finds matches
- **Exact Matches**: One-to-one matches are processed first
- **Combination Matches**: Multiple transaction combinations are calculated
- **Terminal-based Matches**: Special priority for terminal code groupings

### **Step 4: Combination Selection - انتخاب ترکیب‌ها**
- **Review Options**: Each payment shows available combination options
- **Select Combinations**: Choose the best matching combination for each payment
- **Real-time Updates**: Other options update automatically to prevent conflicts
- **Terminal Priority**: Terminal-based combinations are highlighted and prioritized

### **Step 5: Finalization - نهایی‌سازی**
- **Review Results**: Check all selected matches
- **Export Results**: Save the reconciliation results
- **Generate Report**: Create detailed matching report

---

## 🏷️ Badge System - سیستم نشانه‌ها

### **Badge Types - انواع نشانه‌ها**

| Badge | Description | Color |
|-------|-------------|-------|
| 🌳 **ترکیب ترمینال** | Terminal-based combination (highest priority) | Blue |
| 📋 **X آیتم** | Number of items in combination | Green |
| 🔗 **ترمینال واحد** | All items from single terminal | Blue |
| 🔌 **ترمینال‌های متعدد** | Items from multiple terminals | Orange |

---

## ⚙️ Configuration - تنظیمات

### **Performance Settings - تنظیمات عملکرد**
- **Max Combination Size**: Configurable limit for combination members (default: 10)
- **Processing Time Limit**: Maximum time for combination calculations (default: 30 seconds)
- **Amount Precision**: Integer-based amounts for exact calculations
- **Memory Optimization**: Efficient handling of large datasets

### **File Format Support - پشتیبانی از فرمت فایل**
- **Input Formats**: Excel (.xlsx, .xls), CSV (.csv)
- **Output Formats**: Excel (.xlsx), JSON (.json)
- **Encoding**: UTF-8 support for Persian text
- **Column Types**: Text, numbers, dates supported

---

## 🔧 Troubleshooting - عیب‌یابی

### **Common Issues - مشکلات رایج**

**File Loading Errors**
- Ensure files are not open in other applications
- Check file format compatibility
- Verify file permissions

**Processing Time Issues**
- Reduce max combination size in settings
- Check available system memory
- Close other resource-intensive applications

**Display Issues**
- Verify display resolution meets minimum requirements
- Check Windows scaling settings
- Update graphics drivers if necessary

---

## 📞 Support - پشتیبانی

### **Getting Help - دریافت کمک**
- **Documentation**: Check the built-in help system
- **Community**: Join our user community forum
- **Technical Support**: Contact support team for technical issues
- **Feature Requests**: Submit suggestions for future versions

### **System Information - اطلاعات سیستم**
- **Version**: Current application version
- **Build Date**: Application build information
- **System Details**: Operating system and hardware information
- **Log Files**: Application logs for troubleshooting

---

## 🔒 Privacy & Security - حریم خصوصی و امنیت

### **Data Handling - مدیریت داده**
- **Local Processing**: All data processing happens locally on your machine
- **No Cloud Storage**: Files are not uploaded to external servers
- **Temporary Files**: Temporary processing files are automatically cleaned up
- **Data Privacy**: Your financial data remains completely private

---

## 📄 License - مجوز

This application is licensed under the [MIT License](LICENSE) - see the LICENSE file for details.

این نرم‌افزار تحت مجوز [MIT License](LICENSE) منتشر شده است - برای جزئیات فایل LICENSE را مشاهده کنید.

---

## 🚀 Getting Started - شروع کار

1. **Install** the application using this installer
2. **Launch** Matchify Desktop from your Start Menu
3. **Upload** your payment and bank files
4. **Configure** column selections and options
5. **Process** and review automatic matches
6. **Select** the best combinations for your needs
7. **Export** your reconciliation results

---

**🎯 Matchify Desktop** - Making financial reconciliation simple, accurate, and efficient.

**🎯 Matchify Desktop** - ساده، دقیق و کارآمد کردن تطبیق مالی.

---

*Version: 1.0.0 | Build Date: 1404 / 05 | Flutter: 3.8.1*
