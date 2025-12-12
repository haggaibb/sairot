#!/usr/bin/env python3
"""
Generate comprehensive PDF documentation for Sairot app.
This script creates a detailed PDF covering app overview, technology stack, and project structure.
"""

import os
import sys
import yaml
import glob
from datetime import datetime
from pathlib import Path
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.lib import colors
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, PageBreak, Table, TableStyle, Preformatted
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_RIGHT, TA_JUSTIFY

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

def fix_hebrew_text(text):
    """Fix Hebrew text direction for PDF rendering.
    
    Reportlab doesn't handle RTL well. We reverse Hebrew strings because
    they're stored in logical order (LTR in memory) but need to be displayed RTL.
    When reportlab renders them LTR character-by-character, they appear mirrored.
    """
    import re
    
    # Unicode directional markers
    RLE = '\u202B'  # Right-to-Left Embedding  
    PDF = '\u202C'  # Pop Directional Formatting
    
    # Check if text contains Hebrew characters (Unicode range: U+0590 to U+05FF)
    has_hebrew = any('\u0590' <= char <= '\u05FF' for char in text)
    
    if not has_hebrew:
        return text
    
    # For pure Hebrew strings (or strings that are mostly Hebrew), reverse them
    # This is because Hebrew is stored LTR but displayed RTL
    # When reportlab renders LTR, reversing fixes the display order
    hebrew_chars = sum(1 for c in text if '\u0590' <= c <= '\u05FF')
    total_printable = len([c for c in text if c.isprintable() and not c.isspace()])
    
    # If more than 50% Hebrew, reverse the entire string
    if total_printable > 0 and hebrew_chars / total_printable > 0.5:
        # Reverse the string to fix RTL display
        reversed_text = text[::-1]
        return f"{RLE}{reversed_text}{PDF}"
    
    # For mixed text, use RTL markers but don't reverse (would break English)
    return f"{RLE}{text}{PDF}"

def create_paragraph(text, style, force_rtl=False):
    """Create a Paragraph with automatic Hebrew RTL wrapping."""
    # Check if text contains Hebrew
    has_hebrew = any('\u0590' <= char <= '\u05FF' for char in text) or force_rtl
    
    if has_hebrew:
        # Use RTL markers and right alignment for Hebrew text
        rtl_style = ParagraphStyle(
            style.name + '_RTL',
            parent=style,
            alignment=TA_RIGHT if style.alignment == TA_LEFT or style.alignment == TA_JUSTIFY else style.alignment
        )
        return Paragraph(fix_hebrew_text(text), rtl_style)
    return Paragraph(text, style)

def find_hebrew_font():
    """Find and register a Hebrew-supporting font."""
    # Common locations for Hebrew fonts on macOS
    font_paths = [
        "/System/Library/Fonts/Supplemental/Arial Unicode.ttf",
        "/Library/Fonts/Arial Unicode.ttf",
        "/System/Library/Fonts/SFHebrew.ttf",
        "/System/Library/Fonts/Supplemental/Raanana.ttc",
    ]
    
    for font_path in font_paths:
        if os.path.exists(font_path):
            try:
                # Register the font with reportlab
                pdfmetrics.registerFont(TTFont('HebrewFont', font_path))
                print(f"Registered Hebrew font: {font_path}")
                return 'HebrewFont'
            except Exception as e:
                print(f"Warning: Could not register font {font_path}: {e}")
                continue
    
    # Fallback: try to find any Arial Unicode font
    for pattern in ['**/Arial Unicode*.ttf', '**/Arial Unicode*.ttc']:
        for font_path in glob.glob(pattern, recursive=True):
            if os.path.exists(font_path):
                try:
                    pdfmetrics.registerFont(TTFont('HebrewFont', font_path))
                    print(f"Registered Hebrew font: {font_path}")
                    return 'HebrewFont'
                except Exception as e:
                    continue
    
    print("Warning: No Hebrew font found. Hebrew text may not render correctly.")
    return 'Helvetica'  # Fallback to default

def parse_pubspec():
    """Parse pubspec.yaml to extract dependencies and app info."""
    pubspec_path = project_root / "pubspec.yaml"
    with open(pubspec_path, 'r', encoding='utf-8') as f:
        return yaml.safe_load(f)

def get_directory_structure(directory, prefix="", max_depth=3, current_depth=0):
    """Generate directory structure tree."""
    if current_depth >= max_depth:
        return ""
    
    structure = []
    try:
        items = sorted(os.listdir(directory))
        dirs = [d for d in items if os.path.isdir(os.path.join(directory, d)) and not d.startswith('.')]
        files = [f for f in items if os.path.isfile(os.path.join(directory, f)) and not f.startswith('.')]
        
        for i, item in enumerate(dirs + files):
            is_last = i == len(dirs + files) - 1
            current_prefix = "└── " if is_last else "├── "
            structure.append(f"{prefix}{current_prefix}{item}")
            
            if os.path.isdir(os.path.join(directory, item)):
                extension = "    " if is_last else "│   "
                sub_structure = get_directory_structure(
                    os.path.join(directory, item),
                    prefix + extension,
                    max_depth,
                    current_depth + 1
                )
                structure.extend(sub_structure)
    except PermissionError:
        pass
    
    return structure

def categorize_dependencies(dependencies):
    """Categorize dependencies by type."""
    categories = {
        'State Management': ['get'],
        'Firebase': ['firebase', 'cloud_firestore'],
        'Local Storage': ['hive'],
        'UI Components': ['pluto_grid', 'fl_chart', 'webview'],
        'Media': ['camera', 'image_picker'],
        'Utilities': ['connectivity', 'wakelock', 'intl', 'path_provider'],
        'Build Tools': ['build_runner', 'flutter_launcher_icons', 'flutter_native_splash'],
        'Other': []
    }
    
    categorized = {cat: [] for cat in categories.keys()}
    
    for dep_name, dep_info in dependencies.items():
        if isinstance(dep_info, dict):
            continue  # Skip complex dependencies
        
        categorized_flag = False
        for category, keywords in categories.items():
            if category == 'Other':
                continue
            if any(keyword in dep_name.lower() for keyword in keywords):
                version = dep_info if isinstance(dep_info, str) else str(dep_info)
                categorized[category].append((dep_name, version))
                categorized_flag = True
                break
        
        if not categorized_flag:
            version = dep_info if isinstance(dep_info, str) else str(dep_info)
            categorized['Other'].append((dep_name, version))
    
    return categorized

def create_pdf():
    """Create the PDF documentation."""
    output_path = project_root / "app_documentation.pdf"
    
    # Parse pubspec.yaml
    pubspec = parse_pubspec()
    
    # Create PDF document
    doc = SimpleDocTemplate(
        str(output_path),
        pagesize=A4,
        rightMargin=72,
        leftMargin=72,
        topMargin=72,
        bottomMargin=18
    )
    
    # Container for PDF content
    story = []
    
    # Define styles (using default fonts)
    styles = getSampleStyleSheet()
    
    # Custom styles with default fonts
    title_style = ParagraphStyle(
        'CustomTitle',
        parent=styles['Heading1'],
        fontSize=24,
        textColor=colors.HexColor('#1a237e'),
        spaceAfter=30,
        alignment=TA_CENTER
    )
    
    heading1_style = ParagraphStyle(
        'CustomHeading1',
        parent=styles['Heading1'],
        fontSize=18,
        textColor=colors.HexColor('#283593'),
        spaceAfter=12,
        spaceBefore=12
    )
    
    heading2_style = ParagraphStyle(
        'CustomHeading2',
        parent=styles['Heading2'],
        fontSize=14,
        textColor=colors.HexColor('#3949ab'),
        spaceAfter=8,
        spaceBefore=8
    )
    
    normal_style = ParagraphStyle(
        'CustomNormal',
        parent=styles['Normal'],
        fontSize=10,
        spaceAfter=6,
        alignment=TA_JUSTIFY
    )
    
    code_style = ParagraphStyle(
        'CodeStyle',
        parent=styles['Code'],
        fontSize=8,
        fontName='Courier',
        spaceAfter=6
    )
    
    # Title Page
    story.append(Spacer(1, 2*inch))
    story.append(Paragraph("Sairot", title_style))
    story.append(Paragraph("Scouting Days Tests", title_style))
    story.append(Spacer(1, 0.5*inch))
    # Create styles for title page
    title_page_heading = ParagraphStyle(
        'TitlePageHeading',
        parent=styles['Heading2'],
        fontSize=16
    )
    title_page_normal = ParagraphStyle(
        'TitlePageNormal',
        parent=styles['Normal'],
        fontSize=10
    )
    
    story.append(Paragraph("App Documentation", title_page_heading))
    story.append(Spacer(1, 0.3*inch))
    story.append(Paragraph(f"Version: {pubspec.get('version', 'N/A')}", title_page_normal))
    story.append(Paragraph(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}", title_page_normal))
    story.append(PageBreak())
    
    # Table of Contents
    story.append(Paragraph("Table of Contents", heading1_style))
    toc_items = [
        "1. Executive Summary",
        "2. App Overview",
        "3. Technology Stack",
        "4. Project Structure",
        "5. Architecture",
        "6. Key Features",
        "7. Development Setup",
        "8. Appendix"
    ]
    for item in toc_items:
        story.append(Paragraph(item, normal_style))
    story.append(PageBreak())
    
    # 1. Executive Summary
    story.append(Paragraph("1. Executive Summary", heading1_style))
    story.append(Paragraph(
        "Sairot is a Flutter-based mobile application designed for managing and tracking "
        "scouting/reconnaissance day assessments and tests. The application serves instructors in "
        "organizing events, tracking participant performance across multiple test types, "
        "and generating comprehensive reports. Built with modern Flutter architecture and Firebase backend, "
        "the app provides offline-first functionality with cloud synchronization capabilities.",
        normal_style
    ))
    story.append(PageBreak())
    
    # 2. App Overview
    story.append(Paragraph("2. App Overview", heading1_style))
    
    story.append(Paragraph("2.1 Purpose", heading2_style))
    story.append(Paragraph(
        "The application is designed for instructors to manage scouting day events, "
        "track participant performance across various physical and mental assessments, and generate "
        "comprehensive reports. The app provides a comprehensive workflow for instructors to manage "
        "events, track tests, and record participant grades.",
        normal_style
    ))
    
    story.append(Paragraph("2.2 User Roles", heading2_style))
    story.append(Paragraph("<b>Instructors:</b>", normal_style))
    story.append(Paragraph(
        "• Login with instructor ID<br/>"
        "• Create and manage events<br/>"
        "• Track test progress (Meshulash, Alonka, Bur, Sakim, Leadership, Interview)<br/>"
        "• Record participant grades and comments<br/>"
        "• View participant performance and status<br/>"
        "• Generate event reports",
        normal_style
    ))
    
    story.append(Paragraph("2.3 Key Features", heading2_style))
    story.append(Paragraph(
        "• <b>Event Management:</b> Create, manage, and finalize scouting day events<br/>"
        "• <b>Test Tracking:</b> Track six different test types with detailed scoring<br/>"
        "• <b>Participant Management:</b> Manage participant status, grades, and comments<br/>"
        "• <b>Offline Support:</b> Full functionality without internet connection<br/>"
        "• <b>Cloud Sync:</b> Automatic synchronization with Firebase when online<br/>"
        "• <b>Responsive Design:</b> Optimized for both mobile and tablet devices<br/>"
        "• <b>Theme Support:</b> Light and dark mode options<br/>"
        "• <b>Accessibility:</b> Adjustable font sizes and UI scaling",
        normal_style
    ))
    story.append(PageBreak())
    
    # 3. Technology Stack
    story.append(Paragraph("3. Technology Stack", heading1_style))
    
    story.append(Paragraph("3.1 Framework", heading2_style))
    story.append(Paragraph(
        f"<b>Flutter:</b> {pubspec.get('environment', {}).get('sdk', '3.6.1+')}<br/>"
        "Flutter is Google's UI toolkit for building natively compiled applications for mobile, web, "
        "and desktop from a single codebase. The app uses Flutter 3.6.1+ with Dart SDK.",
        normal_style
    ))
    
    # Parse and categorize dependencies
    deps = pubspec.get('dependencies', {})
    dev_deps = pubspec.get('dev_dependencies', {})
    categorized = categorize_dependencies(deps)
    
    story.append(Paragraph("3.2 State Management", heading2_style))
    story.append(Paragraph(
        "<b>GetX 4.6.6:</b> A powerful state management, dependency injection, and route management solution. "
        "GetX provides reactive programming with minimal boilerplate, making it ideal for Flutter applications. "
        "The app uses GetX controllers for business logic and reactive state management.",
        normal_style
    ))
    
    story.append(Paragraph("3.3 Backend Services", heading2_style))
    story.append(Paragraph(
        "<b>Firebase Core 3.10.1:</b> Firebase initialization and configuration<br/>"
        "<b>Cloud Firestore 5.6.2:</b> NoSQL document database for storing events, participants, and grades. "
        "Supports offline persistence and real-time synchronization.<br/>"
        "<b>Firebase Storage 12.4.1:</b> Cloud storage for media files and documents<br/>"
        "<b>Firebase Vertex AI 1.2.0:</b> AI-powered features for participant analysis",
        normal_style
    ))
    
    story.append(Paragraph("3.4 Local Storage", heading2_style))
    story.append(Paragraph(
        "<b>Hive 2.2.3:</b> Lightweight, fast key-value database for local data persistence. "
        "Used for caching system settings, user preferences, and offline data storage.<br/>"
        "<b>Hive Flutter 1.1.0:</b> Flutter bindings for Hive<br/>"
        "<b>Path Provider 2.1.4:</b> Provides platform-specific paths for storing local data",
        normal_style
    ))
    
    story.append(Paragraph("3.5 UI Components", heading2_style))
    story.append(Paragraph(
        "<b>PlutoGrid 8.0.0:</b> Advanced data grid widget for displaying and editing tabular data. "
        "Used in the grades page for displaying participant grades.<br/>"
        "<b>fl_chart 0.70.2:</b> Feature-rich charting library for creating beautiful charts and graphs. "
        "Used for displaying performance analytics and grade distributions.<br/>"
        "<b>WebView Flutter 4.13.0:</b> WebView widget for displaying HTML content, used for user guides and documentation.",
        normal_style
    ))
    
    story.append(Paragraph("3.6 Other Dependencies", heading2_style))
    story.append(Paragraph(
        "<b>connectivity_plus 6.1.2:</b> Network connectivity status monitoring<br/>"
        "<b>camera 0.10.5+9:</b> Camera functionality for capturing images<br/>"
        "<b>image_picker 1.0.6:</b> Image selection from gallery or camera<br/>"
        "<b>wakelock_plus 1.2.9:</b> Prevents screen from turning off during tests<br/>"
        "<b>intl 0.19.0:</b> Internationalization and localization support<br/>"
        "<b>flutter_localization 0.2.3:</b> Additional localization features",
        normal_style
    ))
    
    story.append(Paragraph("3.7 Build Tools", heading2_style))
    story.append(Paragraph(
        "<b>build_runner 2.4.15:</b> Code generation tool for Hive adapters and other generated code<br/>"
        "<b>flutter_launcher_icons 0.14.3:</b> Generates app launcher icons<br/>"
        "<b>flutter_native_splash 2.3.10:</b> Generates native splash screens",
        normal_style
    ))
    story.append(PageBreak())
    
    # 4. Project Structure
    story.append(Paragraph("4. Project Structure", heading1_style))
    
    story.append(Paragraph("4.1 Directory Overview", heading2_style))
    story.append(Paragraph(
        "The project follows a well-organized structure with clear separation of concerns:",
        normal_style
    ))
    
    # Generate directory structure
    lib_structure = get_directory_structure(str(project_root / "lib"), max_depth=2)
    structure_text = "lib/\n" + "\n".join(lib_structure[:50])  # Limit to first 50 items
    story.append(Preformatted(structure_text, code_style))
    
    story.append(Paragraph("4.2 Key Directories", heading2_style))
    
    story.append(Paragraph("<b>lib/models/</b>", normal_style))
    story.append(Paragraph(
        "Data models representing the application's domain entities:<br/>"
        "• event.dart - Event data structure<br/>"
        "• participant.dart - Participant information and grades<br/>"
        "• alonka_sprint.dart, sakim_round.dart, meshulash_round.dart - Test-specific models<br/>"
        "• bur.dart - Bur test model<br/>"
        "• instructor.dart - Instructor information<br/>"
        "• grade_settings.dart - Grade calculation settings<br/>"
        "• types.dart - Enumerations and type definitions",
        normal_style
    ))
    
    story.append(Paragraph("<b>lib/pages/</b>", normal_style))
    story.append(Paragraph(
        "UI pages for different app screens (15+ pages):<br/>"
        "• login_page.dart, splash_screen.dart - Authentication<br/>"
        "• home_page.dart - Instructor home dashboard<br/>"
        "• event_home.dart - Event management hub<br/>"
        "• alonka_page.dart, sakim_page.dart, meshulash_page.dart, bur_page.dart - Test pages<br/>"
        "• leadership_page.dart, interview_page.dart - Additional test pages<br/>"
        "• grades_page.dart - Grades overview and editing<br/>"
        "• participants_status_page.dart - Participant status management<br/>"
        "• performance_page.dart - Individual participant performance<br/>"
        "• event_settings_page.dart - Event configuration",
        normal_style
    ))
    
    story.append(Paragraph("<b>lib/widgets/</b>", normal_style))
    story.append(Paragraph(
        "Reusable UI components (27+ widgets):<br/>"
        "• Test-specific widgets: alonka_round_panel.dart, sakim_round_panel.dart, etc.<br/>"
        "• Chart widgets: alonka_charts.dart, bur_charts.dart, meshulash_charts.dart<br/>"
        "• UI components: strobe_button.dart, comments_dialog.dart, guideWebView.dart<br/>"
        "• Grid views: meshulash_grid_view.dart, sakim_grid_view.dart",
        normal_style
    ))
    
    story.append(Paragraph("<b>lib/utils/</b>", normal_style))
    story.append(Paragraph(
        "Utility functions and helpers:<br/>"
        "• logger.dart - Custom logging utility for debugging<br/>"
        "• tablet_utils.dart - Tablet detection and responsive utilities",
        normal_style
    ))
    
    story.append(Paragraph("<b>Controllers</b>", normal_style))
    story.append(Paragraph(
        "Main controllers in lib/ root:<br/>"
        "• event_controller.dart - Core event and participant management<br/>"
        "• theme_controller.dart - Theme and UI preferences<br/>"
        "• connectivity_controller.dart - Network status monitoring",
        normal_style
    ))
    story.append(PageBreak())
    
    # 5. Architecture
    story.append(Paragraph("5. Architecture", heading1_style))
    
    story.append(Paragraph("5.1 Design Pattern", heading2_style))
    story.append(Paragraph(
        "The application follows an <b>MVC-like architecture</b> with GetX controllers:<br/>"
        "• <b>Models:</b> Data structures in lib/models/ representing domain entities<br/>"
        "• <b>Views:</b> UI pages and widgets in lib/pages/ and lib/widgets/<br/>"
        "• <b>Controllers:</b> Business logic and state management in GetX controllers",
        normal_style
    ))
    
    story.append(Paragraph("5.2 State Management", heading2_style))
    story.append(Paragraph(
        "GetX provides reactive state management using Rx variables:<br/>"
        "• Observable variables (Rx<T>) automatically update UI when values change<br/>"
        "• Controllers extend GetxController and manage related state<br/>"
        "• Obx widgets rebuild automatically when observed values change<br/>"
        "• Dependency injection through Get.put() and Get.find()",
        normal_style
    ))
    
    story.append(Paragraph("5.3 Data Flow", heading2_style))
    story.append(Paragraph(
        "<b>Cloud to Local:</b><br/>"
        "1. Firebase Firestore stores events and participant data<br/>"
        "2. Firestore offline persistence caches data locally<br/>"
        "3. Hive provides additional local storage for settings and preferences<br/>"
        "<b>Local to Cloud:</b><br/>"
        "1. User actions update local state in controllers<br/>"
        "2. Changes are saved to Firestore (with offline queue if offline)<br/>"
        "3. Firestore automatically syncs when connection is restored",
        normal_style
    ))
    
    story.append(Paragraph("5.4 Route Management", heading2_style))
    story.append(Paragraph(
        "GetX navigation provides declarative route management:<br/>"
        "• Routes defined in main.dart using GetPage<br/>"
        "• Navigation via Get.toNamed() and Get.offNamed()<br/>"
        "• Route parameters passed through URL-like syntax<br/>"
        "• Custom transitions and route guards supported",
        normal_style
    ))
    
    story.append(Paragraph("5.5 Offline-First Architecture", heading2_style))
    story.append(Paragraph(
        "The app is designed to work offline-first:<br/>"
        "• Firestore enables offline persistence by default<br/>"
        "• All read/write operations work without internet<br/>"
        "• Changes are queued and synced when connection is restored<br/>"
        "• Hive provides additional local caching for critical data<br/>"
        "• Connectivity controller monitors network status",
        normal_style
    ))
    story.append(PageBreak())
    
    # 6. Key Features
    story.append(Paragraph("6. Key Features", heading1_style))
    
    story.append(Paragraph("6.1 Test Types", heading2_style))
    story.append(Paragraph(
        "The app tracks six different test types:<br/>"
        "• <b>Meshulash (Triangle):</b> Team coordination and problem-solving test<br/>"
        "• <b>Alonka (Stretcher):</b> Physical endurance and teamwork test<br/>"
        "• <b>Bur (Pit):</b> Obstacle course and physical challenge<br/>"
        "• <b>Sakim (Bags):</b> Physical strength and endurance test<br/>"
        "• <b>Leadership:</b> Leadership assessment and evaluation<br/>"
        "• <b>Interview:</b> Personal interview and evaluation",
        normal_style
    ))
    
    story.append(Paragraph("6.2 Grade Management", heading2_style))
    story.append(Paragraph(
        "Comprehensive grade tracking and calculation:<br/>"
        "• Individual test grades for each participant<br/>"
        "• System-calculated grades based on test performance<br/>"
        "• Instructor override grades<br/>"
        "• Final grade calculation with configurable weights<br/>"
        "• Grade distribution charts and analytics",
        normal_style
    ))
    
    story.append(Paragraph("6.3 Participant Management", heading2_style))
    story.append(Paragraph(
        "Full participant lifecycle management:<br/>"
        "• Participant status tracking (Active, Inactive, etc.)<br/>"
        "• Drag-and-drop status changes<br/>"
        "• Individual performance pages with detailed analytics<br/>"
        "• Comment system for each test type<br/>"
        "• AI-powered participant reports",
        normal_style
    ))
    
    story.append(Paragraph("6.4 Responsive Design", heading2_style))
    story.append(Paragraph(
        "Optimized for multiple device types:<br/>"
        "• Mobile-first design with tablet optimizations<br/>"
        "• Responsive grid layouts (3 columns mobile, 4 columns tablet)<br/>"
        "• Scaled fonts and UI elements for tablets<br/>"
        "• Touch-optimized controls and gestures<br/>"
        "• Portrait-only orientation",
        normal_style
    ))
    
    story.append(Paragraph("6.5 Theme and Accessibility", heading2_style))
    story.append(Paragraph(
        "User customization options:<br/>"
        "• Light and dark theme support<br/>"
        "• Adjustable font sizes (Normal, Big, Biggest)<br/>"
        "• Customizable UI element sizes",
        normal_style
    ))
    story.append(PageBreak())
    
    # 7. Development Setup
    story.append(Paragraph("7. Development Setup", heading1_style))
    
    story.append(Paragraph("7.1 Prerequisites", heading2_style))
    story.append(Paragraph(
        "• Flutter SDK 3.6.1 or higher<br/>"
        "• Dart SDK<br/>"
        "• Android Studio / Xcode (for mobile development)<br/>"
        "• Firebase project setup<br/>"
        "• Git for version control",
        normal_style
    ))
    
    story.append(Paragraph("7.2 Installation", heading2_style))
    story.append(Paragraph(
        "1. Clone the repository<br/>"
        "2. Run 'flutter pub get' to install dependencies<br/>"
        "3. Configure Firebase (place google-services.json in android/app/)<br/>"
        "4. Run 'flutter run' to start the app",
        normal_style
    ))
    
    story.append(Paragraph("7.3 Platform Support", heading2_style))
    story.append(Paragraph(
        "• <b>Android:</b> Minimum SDK 23, Target SDK 36<br/>"
        "• <b>Web:</b> Supported (requires separate Firebase web configuration)<br/>"
        "• <b>iOS:</b> Not currently configured",
        normal_style
    ))
    story.append(PageBreak())
    
    # 8. Appendix
    story.append(Paragraph("8. Appendix", heading1_style))
    
    story.append(Paragraph("8.1 Complete Dependencies List", heading2_style))
    
    # Create dependency table
    dep_data = [['Package', 'Version', 'Category']]
    for category, deps_list in categorized.items():
        if deps_list:
            for dep_name, version in deps_list:
                dep_data.append([dep_name, version, category])
    
    dep_table = Table(dep_data, colWidths=[3*inch, 1.5*inch, 1.5*inch])
    dep_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, 0), 10),
        ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
        ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
        ('GRID', (0, 0), (-1, -1), 1, colors.black)
    ]))
    story.append(dep_table)
    
    story.append(Spacer(1, 0.2*inch))
    
    story.append(Paragraph("8.2 File Count Summary", heading2_style))
    story.append(Paragraph(
        f"• Models: 15+ files<br/>"
        f"• Pages: 15+ files<br/>"
        f"• Widgets: 27+ files<br/>"
        f"• Controllers: 4 main controllers<br/>"
        f"• Total Dart files: 60+",
        normal_style
    ))
    
    # Build PDF
    doc.build(story)
    print(f"PDF documentation generated successfully: {output_path}")

if __name__ == "__main__":
    try:
        create_pdf()
    except Exception as e:
        print(f"Error generating PDF: {e}", file=sys.stderr)
        sys.exit(1)

