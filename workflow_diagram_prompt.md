# Aarogya Sahayak - Comprehensive Workflow Diagram Generation Prompt

## Project Overview
Aarogya Sahayak is an offline-first mobile health platform designed to bridge the healthcare gap in rural India by connecting patients with ASHA (Accredited Social Health Activist) workers. The platform supports multiple languages and operates seamlessly in low-connectivity environments.

## Core Architecture Components

### Frontend Layer
- **Technology**: Flutter with Provider state management pattern
- **Platform**: Cross-platform mobile application (Android/iOS)
- **UI Structure**: ~20 screens divided between Patient and ASHA interfaces
- **Offline-First Design**: Full functionality available without internet connectivity

### State Management Providers
- AuthProvider: User authentication and role management
- VitalsProvider: Health metrics tracking and trends
- LanguageProvider: Multi-language support (Hindi, English, regional languages)
- ReportsProvider: Medical report management with OCR
- RemindersProvider: Medication and appointment reminders
- ASHAProvider: ASHA worker details and patient assignments
- ConnectivityProvider: Network status and sync coordination
- NotificationProvider: Push notifications and alerts

### Core Services
- **OfflineSyncService**: Bidirectional data synchronization
- **OCRService**: Medical report text extraction using ML Kit
- **CameraVitalsService**: Camera-based health measurements
- **SOSAlertService**: Emergency response system
- **NotificationService**: Firebase Cloud Messaging integration
- **LocalStorageService**: Hive database with SharedPreferences fallback

### Backend Infrastructure
- **Authentication**: Firebase Auth with role-based access
- **Database**: Firestore with offline persistence
- **Storage**: Firebase Storage for images and documents
- **Messaging**: Firebase Cloud Messaging for notifications
- **Analytics**: Firebase Analytics for usage insights
- **Configuration**: Firebase Remote Config for feature flags

## User Roles and Permissions

### Patient/User Role
- **Profile Management**: Personal health information, emergency contacts
- **Vitals Tracking**: Blood pressure, blood sugar, weight, heart rate, BMI
- **Report Management**: Upload medical reports, OCR text extraction, categorization
- **Reminders**: Medication schedules, appointment alerts, health checkups
- **Health Education**: Curated content feed, preventive care tips
- **Communication**: Chat with assigned ASHA workers
- **Emergency Features**: SOS alerts with location sharing
- **Government Services**: Integration with health schemes and services

### ASHA Worker Role
- **Patient Management**: View assigned patients, health status overview
- **Visit Scheduling**: Plan and track patient visits
- **Health Monitoring**: Review patient vitals and trends
- **Report Analysis**: Access patient reports and medical history
- **Communication Hub**: Multi-patient chat management
- **Analytics Dashboard**: Patient health analytics and insights
- **Emergency Response**: Receive and respond to SOS alerts
- **Data Collection**: Community health data gathering

## Key Workflows to Visualize

### 1. User Onboarding and Authentication Flow
```
Entry Point → Language Selection → Role Selection (Patient/ASHA) → 
Authentication (Phone/Email) → Profile Setup → Dashboard Access
```

### 2. Patient Health Monitoring Workflow
```
Dashboard → Vitals Input (Manual/Camera) → Local Storage → 
Background Sync → Trend Analysis → Report Generation → 
ASHA Notification (if abnormal)
```

### 3. Report Management Workflow
```
Camera Capture → Image Processing → OCR Text Extraction → 
Manual Verification → Categorization → Local Storage → 
Sync to Cloud → ASHA Access → Analysis Feedback
```

### 4. Emergency Response Workflow
```
SOS Trigger → Location Detection → Emergency Contacts Alert → 
ASHA Notification → Response Coordination → Status Updates → 
Resolution Tracking
```

### 5. ASHA Patient Management Workflow
```
Patient Assignment → Health Status Review → Visit Planning → 
Field Visit → Data Collection → Report Update → 
Follow-up Scheduling → Analytics Review
```

### 6. Offline-First Sync Workflow
```
Data Input (Offline) → Local Storage → Connectivity Check → 
Background Sync → Conflict Resolution → Cloud Update → 
Local Cache Update → UI Refresh
```

### 7. Communication Workflow
```
Message Composition → Offline Queue → Delivery Attempt → 
Status Update → Read Receipts → Response Handling → 
Notification Management
```

## Technical Integration Points

### Data Flow Architecture
- **Local-First**: All data operations start locally
- **Eventual Consistency**: Sync when connectivity available
- **Conflict Resolution**: Last-write-wins with timestamp validation
- **Batch Operations**: Efficient sync of multiple changes

### Security Considerations
- **Data Encryption**: Local storage encryption with Hive
- **Secure Authentication**: Firebase Auth with token refresh
- **Privacy Protection**: Personal health data anonymization
- **Access Control**: Role-based permissions and data isolation

## Diagram Requirements

### Primary Workflow Diagram
Create a comprehensive system workflow showing:
1. **User Journey Paths**: Both patient and ASHA user flows
2. **Data Flow**: From input to storage to analysis
3. **Service Interactions**: How core services interconnect
4. **Offline/Online States**: Different behavior modes
5. **Error Handling**: Failure scenarios and recovery paths

### Secondary Specialized Diagrams
1. **Authentication & Role Management Flow**
2. **Health Data Collection & Analysis Pipeline**
3. **Emergency Response System Workflow**
4. **Offline-First Synchronization Architecture**
5. **Communication & Notification System**

## Visual Design Guidelines

### Color Coding Scheme
- **Patient Workflows**: Blue tones (#88c0d0, #81a1c1)
- **ASHA Workflows**: Green tones (#a3be8c, #8fbcbb)
- **Backend Services**: Red tones (#bf616a, #d08770)
- **Data Storage**: Purple tones (#b48ead, #d08770)
- **Communication**: Orange tones (#ebcb8b, #d08770)

### Node Types
- **User Actions**: Rounded rectangles
- **System Processes**: Rectangles
- **Decision Points**: Diamonds
- **Data Stores**: Cylinders
- **External Services**: Hexagons
- **Error States**: Dashed borders

### Flow Indicators
- **Primary Flows**: Solid arrows
- **Alternative Paths**: Dashed arrows
- **Error Paths**: Dotted red arrows
- **Async Operations**: Double-line arrows
- **Data Sync**: Curved arrows

## Output Format
Generate the diagrams using Mermaid syntax with:
- Clear node labeling with role context
- Logical grouping using subgraphs
- Proper styling classes for visual clarity
- Comments explaining complex decision points
- Multiple diagram views for different perspectives

## Success Metrics
The generated workflow diagrams should enable:
1. **Developer Understanding**: Clear technical implementation guide
2. **Stakeholder Communication**: Non-technical audience comprehension
3. **System Documentation**: Complete workflow documentation
4. **Troubleshooting Guide**: Error path identification
5. **Feature Planning**: Future enhancement visualization

---

*This prompt captures the complete architecture, user workflows, and technical requirements of the Aarogya Sahayak platform for generating comprehensive workflow diagrams that serve both technical and business stakeholders.*