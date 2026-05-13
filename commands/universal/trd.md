# TRD Command (Phase 1: Pre-Implementation)

Generate a Technical Requirement Document for: $ARGUMENTS

## Instructions

### Step 1: Gather PRD & Design Inputs

**Primary inputs** for TRD generation are PRD (Confluence), Figma design, and existing codebase — NOT Jira tickets.

#### 1a. PRD from Confluence (Primary Source of Truth)
If $ARGUMENTS contains a Confluence URL or page ID:
- Use `mcp__atlassian__getConfluencePage` to fetch PRD content
- Extract: requirements, acceptance criteria, business rules, user flows, data models

If $ARGUMENTS describes a feature name (no URL):
- Use `mcp__atlassian__searchConfluenceUsingCql` to search for the PRD in Confluence
- Fetch the matching page with `mcp__atlassian__getConfluencePage`

#### 1b. Figma Design (Screenshots/Mockups)
If $ARGUMENTS contains a Figma URL:
- Use `mcp__figma__get_file_nodes` to fetch design details and screen specs

If user provides screenshot images directly:
- Analyze the screenshots for UI layout, components, navigation flow

#### 1c. BE TRD (Backend Technical Requirement)
If $ARGUMENTS contains `--be-trd` or a BE TRD Confluence URL:
- Use `mcp__atlassian__getConfluencePage` to fetch BE TRD content
- Extract: API contracts, endpoint specs, request/response models, error codes

#### 1d. QA TRD (QA Technical Requirement)
If $ARGUMENTS contains `--qa-trd` or a QA TRD Confluence URL:
- Use `mcp__atlassian__getConfluencePage` to fetch QA TRD content
- Extract: test scenarios, automation scope, acceptance criteria from QA perspective

#### 1e. Jira (Optional — for ticketing/tracking only)
If $ARGUMENTS contains a Jira ticket ID (e.g., {{JIRA_KEY}}, {{JIRA_KEY}}):
- Use `mcp__atlassian__getJiraIssue` to fetch ticket summary, epic, linked issues
- Use `mcp__jira-attachment__list_attachments` + `download_all_images` + `download_all_videos` for attachments
- If videos found, use `mcp__video-to-image__extract_frames_by_count` (count: 5) to extract key frames
- **Note:** Jira is used for tracking context only, not as primary requirement source

### Step 2: Analyze Existing Codebase

1. Identify affected modules from the PRD context
2. Read relevant README.md files for those modules
3. Search codebase for related files (ViewModels, Screens, Repositories, API services, DTOs)
4. Map current architecture (flow diagrams, state management, navigation)
5. Identify files to MODIFY vs CREATE

### Step 3: Generate TRD

Create file at: `.docs/trd/TRD-{Feature-Name}.md`

Use kebab-case for the feature name derived from the Jira ticket summary.
Max 30000 characters.

## TRD Template Structure

```markdown
# Technical Requirement Document (TRD)
## {Feature Name}

**Document Version:** 1.0
**Date:** {current date YYYY-MM-DD}
**Author:** Technical Team
**Status:** Draft
**Jira:** {ticket ID and link}
**Confluence (PRD):** {link if available}
**Confluence (BE TRD):** {link if available, or "N/A"}
**Confluence (QA TRD):** {link if available, or "N/A"}
**Figma:** {link if available}

---

## 1. Executive Summary

### 1.1 Overview
{What this feature does in 2-3 sentences}

### 1.2 Current Implementation
{Describe current behavior with bullet points}

### 1.3 Target Implementation
{Describe target behavior with bullet points}

### 1.4 Business Justification
{Why this change is needed — regulatory, UX, performance, etc.}

### 1.5 Scope Condition
{Any conditions that limit when this feature applies}

---

## 2. Scope

### 2.1 In Scope
{Bullet list of what will be implemented}

### 2.2 Out of Scope
{Bullet list of what will NOT be implemented}

---

## 3. Current Architecture Analysis

### 3.1 Current Flow
{ASCII flow diagram of current behavior}

### 3.2 Target Flow
{ASCII flow diagram of target behavior}

### 3.3 Affected Components
{For each affected file, describe:}

#### 3.3.N {Component Name} ({MODIFY|CREATE|DELETE})
**File:** `{module}/.../path/to/File.kt`
{Description of changes needed with current code snippets}

---

## 4. Data Model
{Request/Response DTOs with field descriptions}
{Field validation rules table}
{Dropdown options if applicable}

---

## 5. Screen Specifications
{For each screen: layout description, behavior, navigation}
{Reference Figma screenshots if available}

---

## 6. API Contract
{From BE TRD if available, otherwise from codebase analysis}
{For each endpoint: method, path, request body, response codes}

### 6.N Field Name Mapping (BE ↔ Mobile ↔ UI)
{Table mapping BE field names to mobile properties to UI labels}

---

## 7. File Structure
{Tree diagram of new/modified files organized by module}

---

## 8. State Management
{State data class definition}
{State flow diagram}

---

## 9. Testing Requirements

### 9.1 Unit Tests
{Table: Test Class | Coverage}

### 9.2 UI Tests
{Table: Test | Scenario}

---

## 10. Risk Assessment
{Table: Risk | Impact | Mitigation}

---

## 11. Implementation Checklist
{Organized by layer: Data, Domain, Presentation, Integration, Testing}
{Each item as checkbox}

---

## 12. Success Metrics
{Table: Metric | Target}

---

## 13. Dependencies
{Table: Dependency | Owner | Status}
```

## Guidelines

- Read all related module README.md files before generating
- Include actual code snippets from codebase for "Current" sections (with file paths)
- Include actual code snippets for "Target" sections showing proposed changes
- If BE TRD is provided, use exact API contracts from it (do not guess endpoints)
- If QA TRD is provided, align testing requirements with QA scenarios
- Use `before/after` code blocks for modified components
- Reference Figma node IDs when available
- Follow existing naming conventions from the codebase
- All dropdown options must match Confluence/PRD spec exactly
- Mark open questions that need BE/QA/Product confirmation