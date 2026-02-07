# XpenseDesk Login & Sign Up Pages - Technical Specification

## Overview

This document describes how to build the **Login Page** and **Sign Up Page** for XpenseDesk, a professional expense management SaaS application. These pages serve as the entry point to the application and implement mock authentication for MVP/design purposes.

---

## 1. Design System & Theme

### 1.1 Typography

**Font Family**: Assistant (Google Fonts)
- Weights available: 100, 200, 300, 400, 500, 600, 700, 800
- Load via Google Fonts CDN with `display=block`

```html

```

**Tailwind Configuration**:
```typescript
fontFamily: {
  sans: ['Assistant', 'system-ui', '-apple-system', 'sans-serif'],
}
```

### 1.2 Color Palette (HSL Format)

| Token | Light Mode | Description |
|-------|------------|-------------|
| `--background` | 240 20% 98% | Page background (off-white with slight purple tint) |
| `--foreground` | 250 30% 15% | Primary text (dark navy-purple) |
| `--card` | 0 0% 100% | Card background (pure white) |
| `--card-foreground` | 250 30% 15% | Card text |
| `--primary` | 250 45% 30% | Primary button/action (deep navy-purple) |
| `--primary-foreground` | 0 0% 100% | Primary button text (white) |
| `--muted` | 250 15% 95% | Subtle backgrounds |
| `--muted-foreground` | 250 10% 45% | Secondary text |
| `--border` | 250 20% 90% | Border color |
| `--destructive` | 330 81% 60% | Error state (pink-red) |

### 1.3 Spacing & Layout

- **Border Radius**: `0.75rem` (12px) - Larger than default for softer appearance
- **Card Max Width**: `max-w-sm` (24rem / 384px)
- **Page Container**: `max-w-5xl` with responsive horizontal padding

### 1.4 Design Tone

- **Calm, professional, trustworthy** (finance SaaS aesthetic)
- Clean white surfaces with subtle purple undertones
- No illustrations or visual noise
- Single focused action per screen
- Minimal copy - if explanation is needed, the UX has failed

---

## 2. Page Structure & Component Hierarchy

### 2.1 Login Page Hierarchy

```text
LoginPage (root)
├── Page Container (min-h-screen flex flex-col)
│   ├── Header
│   │   └── LanguageSwitcher (positioned right)
│   │
│   ├── Main Content (flex-1, centered)
│   │   └── Card (max-w-sm, animate-fade-in)
│   │       ├── CardHeader (text-center)
│   │       │   ├── Logo (img, h-10)
│   │       │   ├── CardTitle ("Log in")
│   │       │   └── CardDescription ("Enter your work email...")
│   │       │
│   │       └── CardContent (space-y-4)
│   │           ├── Input (email, autofocus)
│   │           ├── Alert (error, conditional)
│   │           ├── Button ("Continue", full-width)
│   │           └── Link Text ("Don't have an account? Create account")
│   │
│   └── Footer
│       ├── Copyright
│       └── Legal Links (Privacy, Terms)
```

### 2.2 Sign Up Page Hierarchy

```text
SignUpPage (root)
├── Page Container (min-h-screen flex flex-col)
│   ├── Header
│   │   └── LanguageSwitcher
│   │
│   ├── Main Content (flex-1, centered)
│   │   └── Card (max-w-sm, animate-fade-in)
│   │       ├── CardHeader (text-center)
│   │       │   ├── Logo
│   │       │   ├── CardTitle ("Create account")
│   │       │   └── CardDescription ("Start managing...")
│   │       │
│   │       └── CardContent (space-y-4)
│   │           ├── Field: Full Name (Label + Input)
│   │           ├── Field: Work Email (Label + Input)
│   │           ├── Field: Company Name (Label + Input)
│   │           ├── Alert (error, conditional)
│   │           ├── Button ("Get Started", full-width)
│   │           └── Link Text ("Already have an account? Log in")
│   │
│   └── Footer
```

---

## 3. Component Dependencies

### 3.1 UI Components (from shadcn/ui)

| Component | Import Path | Purpose |
|-----------|-------------|---------|
| `Card`, `CardHeader`, `CardTitle`, `CardDescription`, `CardContent` | `@/components/ui/card` | Main container |
| `Input` | `@/components/ui/input` | Form fields |
| `Button` | `@/components/ui/button` | Primary actions |
| `Label` | `@/components/ui/label` | Form field labels (Sign Up only) |
| `Alert`, `AlertDescription` | `@/components/ui/alert` | Error messages |

### 3.2 Application Components

| Component | Import Path | Purpose |
|-----------|-------------|---------|
| `LanguageSwitcher` | `@/components/LanguageSwitcher` | EN/HE language toggle |

### 3.3 Hooks & Context

| Hook | Import Path | Purpose |
|------|-------------|---------|
| `useNavigate` | `react-router-dom` | Programmatic navigation |
| `Link` | `react-router-dom` | Declarative navigation links |
| `useLanguage` | `@/i18n` | Access translations (`t` object) |

### 3.4 Assets

| Asset | Import Path | Purpose |
|-------|-------------|---------|
| `logo` | `@/assets/logo.png` | Product logo image |

---

## 4. Business Logic

### 4.1 Mock Authentication (Login Page)

This is **mock-only logic** for MVP. No real authentication.

**Mock User Database**:
```typescript
const MOCK_USERS: Record = {
  'erez0502760106@gmail.com': 'manager',
  'user@domain.com': 'employee',
};
```

**Login Flow**:

1. User enters email
2. On "Continue" click or Enter key:
   - Validate email format using regex
   - Normalize email (lowercase, trim)
   - Look up in mock database
3. Outcomes:
   - **Manager email** → Navigate to `/manager/dashboard`
   - **Employee email** → Navigate to `/employee/dashboard`
   - **Unknown email** → Show error: "This email is not registered in the system"
   - **Invalid format** → Show error: "Please enter a valid email address"

**Email Validation Regex**:
```typescript
const isValidEmail = (email: string) => {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
};
```

### 4.2 Sign Up Flow

**Form Fields**:
- Full Name (required)
- Work Email (required, validated)
- Company Name (required)

**Validation**:
- All fields must be non-empty
- Email must pass format validation

**Mock Behavior**:
- On successful submission → Navigate to `/manager/dashboard`
- New account owner is assumed to be a Manager

### 4.3 State Management

**Login Page State**:
```typescript
const [email, setEmail] = useState('');
const [error, setError] = useState('');
```

**Sign Up Page State**:
```typescript
const [formData, setFormData] = useState({
  name: '',
  email: '',
  companyName: '',
});
const [error, setError] = useState('');
```

### 4.4 Button States

- **Login "Continue" Button**: Disabled when email is empty
- **Sign Up "Get Started" Button**: Disabled when any field is empty

---

## 5. Internationalization (i18n)

### 5.1 Supported Languages

- English (`en`)
- Hebrew (`he`) - RTL support

### 5.2 Translation Keys Used

| Key | English | Hebrew |
|-----|---------|--------|
| `loginTitle` | "Log in" | "התחברות" |
| `loginSubtext` | "Enter your work email to continue" | "הזן את האימייל העסקי שלך כדי להמשיך" |
| `continue` | "Continue" | "המשך" |
| `invalidEmailFormat` | "Please enter a valid email address" | "אנא הזן כתובת אימייל תקינה" |
| `emailNotRegistered` | "This email is not registered in the system" | "אימייל זה אינו רשום במערכת" |
| `noAccount` | "Don't have an account?" | "אין לך חשבון?" |
| `createAccount` | "Create account" | "צור חשבון" |
| `createAccountSubtext` | "Start managing your team expenses" | "התחל לנהל את הוצאות הצוות שלך" |
| `fullName` | "Full Name" | "שם מלא" |
| `fullNamePlaceholder` | "John Smith" | "ישראל ישראלי" |
| `workEmail` | "Work Email" | "אימייל עסקי" |
| `companyNamePlaceholder` | "Acme Inc." | "חברה בע״מ" |
| `getStarted` | "Get Started" | "התחל" |
| `alreadyHaveAccount` | "Already have an account?" | "כבר יש לך חשבון?" |
| `logIn` | "Log in" | "התחבר" |
| `privacyPolicy` | "Privacy Policy" | "מדיניות פרטיות" |
| `termsOfService` | "Terms of Service" | "תנאי שימוש" |
| `allRightsReserved` | "All rights reserved" | "כל הזכויות שמורות" |
| `appName` | "XpenseDesk" | "XpenseDesk" |

---

## 6. Routing Configuration

**Routes** (in `App.tsx`):

```typescript

  } />
  } />
  {/* ... other routes */}

```

**Navigation Paths**:
- Login page: `/`
- Sign up page: `/signup`
- Manager dashboard: `/manager/dashboard`
- Employee dashboard: `/employee/dashboard`

---

## 7. Animations

**Fade-in Animation** (applied to Card):

```typescript
// tailwind.config.ts
keyframes: {
  "fade-in": {
    from: { opacity: "0", transform: "translateY(8px)" },
    to: { opacity: "1", transform: "translateY(0)" },
  },
},
animation: {
  "fade-in": "fade-in 0.3s ease-out",
},
```

**Usage**: `className="animate-fade-in"`

---

## 8. Explicitly NOT Included (Out of Scope)

Per the MVP specification, the following are **intentionally excluded**:

- Password field
- OTP/Magic link authentication
- Social login (Google, etc.)
- Forgot password flow
- Loading spinners
- Session handling/persistence
- Remember-me checkbox
- Role selector dropdown
- Company selector dropdown
- Help text or tooltips

These pages serve as **design gates**, not functional authentication.

---

## 9. File Structure

```text
src/
├── pages/
│   ├── LoginPage.tsx       # Main login page
│   └── SignUpPage.tsx      # Registration page
├── components/
│   ├── LanguageSwitcher.tsx
│   └── ui/
│       ├── card.tsx
│       ├── input.tsx
│       ├── button.tsx
│       ├── label.tsx
│       └── alert.tsx
├── assets/
│   └── logo.png            # Product logo
├── i18n/
│   ├── dictionaries.ts     # Translation strings
│   ├── LanguageContext.tsx # Language context provider
│   └── index.ts
└── App.tsx                 # Route definitions
```

---

## 10. Code Example - Login Page

```tsx
import { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useLanguage } from '@/i18n';
import { LanguageSwitcher } from '@/components/LanguageSwitcher';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Alert, AlertDescription } from '@/components/ui/alert';
import logo from '@/assets/logo.png';

const MOCK_USERS: Record = {
  'erez0502760106@gmail.com': 'manager',
  'user@domain.com': 'employee',
};

export default function LoginPage() {
  const navigate = useNavigate();
  const { t } = useLanguage();
  const [email, setEmail] = useState('');
  const [error, setError] = useState('');

  const isValidEmail = (email: string) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);

  const handleContinue = () => {
    setError('');
    if (!email.trim()) return;
    if (!isValidEmail(email)) {
      setError(t.invalidEmailFormat);
      return;
    }
    const userRole = MOCK_USERS[email.toLowerCase().trim()];
    if (userRole === 'manager') navigate('/manager/dashboard');
    else if (userRole === 'employee') navigate('/employee/dashboard');
    else setError(t.emailNotRegistered);
  };

  return (

              {t.loginTitle}
              {t.loginSubtext}

             setEmail(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && handleContinue()}
              autoFocus
            />
            {error && (

                {error}

            )}

              {t.continue}

              {t.noAccount}{' '}

                {t.createAccount}

            © {new Date().getFullYear()} {t.appName}. {t.allRightsReserved}.

              {t.privacyPolicy}
              {t.termsOfService}

  );
}
```

 