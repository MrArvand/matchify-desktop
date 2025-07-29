# Matchify Desktop

A powerful Flutter desktop application for matching payment records with receivable records using efficient algorithms. Built with beautiful UI and optimized for performance.

## 🚀 Features

- **Excel File Processing**: Support for both .xlsx and .xls files
- **Efficient Matching Algorithms**:
  - Exact amount matching
  - Combination matching (2-3 receivables combined)
  - Optimized for up to 10,000 records per file
- **Beautiful UI**: Modern Material Design with Vazirmatn font
- **Progress Tracking**: Real-time progress indicators
- **Export Functionality**: Export results to Excel and CSV formats
- **Persian Language Support**: RTL layout and Persian number formatting
- **Performance Optimized**: Completes matching within 30-60 seconds

## 📋 Requirements

- Flutter 3.10.0 or higher
- Dart 3.0.0 or higher
- Windows 10/11
- 8GB RAM recommended
- i5 CPU or equivalent

## 🛠️ Installation

1. **Clone the repository**:

   ```bash
   git clone https://github.com/your-username/matchify-desktop.git
   cd matchify-desktop
   ```

2. **Install dependencies**:

   ```bash
   flutter pub get
   ```

3. **Download Vazirmatn font**:
   Create the `assets/fonts/` directory and download the Vazirmatn font files:

   - Vazirmatn-Regular.ttf
   - Vazirmatn-Medium.ttf
   - Vazirmatn-Bold.ttf

   You can download them from [Google Fonts](https://fonts.google.com/specimen/Vazirmatn)

4. **Run the application**:
   ```bash
   flutter run -d windows
   ```

## 📖 Usage

### 1. Upload Files

- Click "Upload Files" tab
- Select your payments Excel file (مبالغ پرداخت‌ها)
- Select your receivables Excel file (مبالغ طلب‌ها)
- Choose the amount column for each file
- Set the starting row (default: 1)

### 2. Start Matching

- Click "Start Matching" button
- Monitor progress in real-time
- Wait for completion (typically 30-60 seconds for 10k records)

### 3. View Results

- Navigate to "Matching Results" tab
- View exact matches, combination matches, and unmatched records
- See detailed statistics and processing time

### 4. Export Results

- Go to "Export" tab
- Choose Excel (.xlsx) or CSV format
- Select save location
- Download your results

## 🧮 Algorithm Details

### Exact Matching

- Finds payments and receivables with identical amounts
- Uses hash-based lookup for O(1) performance
- Handles Persian comma formatting

### Combination Matching

- Finds 2-3 receivables that sum to payment amount
- Uses meet-in-the-middle technique for efficiency
- Prioritizes 2-combinations over 3-combinations
- Implements early termination for performance

### Performance Optimizations

- Sorted input for efficient processing
- Hash maps for O(1) lookups
- Greedy filtering (skip receivables > payment amount)
- Two-pointer technique for 2-combinations
- Meet-in-the-middle for 3-combinations

## 📊 Expected Performance

| Records per File | Processing Time | Memory Usage |
| ---------------- | --------------- | ------------ |
| 1,000            | 5-10 seconds    | ~50MB        |
| 5,000            | 15-25 seconds   | ~150MB       |
| 10,000           | 30-60 seconds   | ~300MB       |

## 🎨 UI Features

- **Modern Design**: Material 3 with custom theming
- **Persian Support**: RTL layout and Persian fonts
- **Responsive**: Adapts to different screen sizes
- **Dark Mode**: Automatic theme switching
- **Progress Indicators**: Real-time feedback
- **Error Handling**: User-friendly error messages

## 📁 Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart
│   ├── models/
│   │   ├── record.dart
│   │   └── matching_result.dart
│   ├── services/
│   │   ├── matching_service.dart
│   │   └── excel_service.dart
│   └── theme/
│       └── app_theme.dart
├── presentation/
│   ├── providers/
│   │   └── matching_provider.dart
│   ├── screens/
│   │   └── home_screen.dart
│   └── widgets/
│       ├── file_upload_section.dart
│       ├── matching_results_section.dart
│       └── export_section.dart
└── main.dart
```

## 🔧 Configuration

### Excel File Format

- First row should contain headers
- Amount column should contain numeric values
- Supports Persian comma formatting (e.g., "1,234,567.89")
- Handles both .xlsx and .xls formats

### Amount Parsing

- Automatically detects Persian/Arabic commas
- Converts to standard decimal format
- Handles various number formats
- Precision: 2 decimal places

## 🐛 Troubleshooting

### Common Issues

1. **Font not loading**:

   - Ensure Vazirmatn font files are in `assets/fonts/`
   - Check file names match pubspec.yaml

2. **Excel file not loading**:

   - Verify file format (.xlsx or .xls)
   - Check file is not corrupted
   - Ensure amount column contains valid numbers

3. **Slow performance**:

   - Close other applications
   - Ensure sufficient RAM (8GB+)
   - Check CPU usage

4. **No matches found**:
   - Verify amount column selection
   - Check data format consistency
   - Review start row setting

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Vazirmatn Font](https://fonts.google.com/specimen/Vazirmatn) by Saber Rasti Kerdar. RIP Saber 💖
- [Flutter](https://flutter.dev/) team for the amazing framework
- [Excel package](https://pub.dev/packages/excel) for Excel file handling

## 📞 Support

For support and questions:

- Create an issue on GitHub
- Email: support@matchify-desktop.com
- Documentation: [Wiki](https://github.com/your-username/matchify-desktop/wiki)

---

**Made with ❤️ for efficient financial record matching**
