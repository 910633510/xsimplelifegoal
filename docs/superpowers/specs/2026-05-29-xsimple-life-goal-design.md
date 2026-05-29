# xsimple Life Goal Design

## Summary

`xsimple Life Goal` is a native SwiftUI iOS app that helps users turn broad life tasks into daily checklists using a fully offline, open-source, mobile-deployable LLM. The user describes a goal and may optionally choose a completion date. If no date is provided, the app uses a one-year timeline from the creation date. The app supports multiple simultaneous goals and presents them on a dashboard.

The first implementation will use `llama.cpp` with a downloadable GGUF model. The default model is `Qwen/Qwen3-1.7B-GGUF`; `Qwen/Qwen3-0.6B-GGUF` is the smaller fallback path for older devices or users who prefer a smaller download. Gemma 3n E4B is not part of the MVP default because it is heavier than needed for text-only goal planning and uses Gemma Terms rather than an Apache-2.0 style license.

## Approved Decisions

- Platform: native SwiftUI iOS app in a new project folder.
- LLM mode: fully offline on-device LLM.
- Runtime approach: `llama.cpp` with GGUF model download after install.
- Default model: `Qwen/Qwen3-1.7B-GGUF`.
- Small fallback model: `Qwen/Qwen3-0.6B-GGUF`.
- Goal scope: multiple active goals with a dashboard.
- Daily work format: short daily checklist, usually one to three concrete actions per day.
- Default timeline: one year when the user does not set a time period.
- Missed-day behavior: spread missed work steadily across all remaining days.

## Product Flow

The app starts at a dashboard showing all active goals. Each goal card shows the title, days left, progress, and today's checklist status. The user can open a goal detail screen or create a new goal.

To create a goal, the user enters a plain-language description such as "learn conversational Spanish" or "prepare for a marathon." The user may select a deadline. If no deadline is selected, the app sets the target date to one year after creation. The app checks that the offline model is ready, then asks the planning engine to generate the first plan.

The goal detail screen puts today's checklist first. The user marks each item complete or leaves it incomplete. At the end of the day, incomplete work is treated as missed work and redistributed across the remaining timeline. The app keeps future checklists balanced so a missed day does not cause a harsh one-day catch-up spike.

## Architecture

The project will be created at `/Users/xue/Project/xsimple-life-goal` as a native SwiftUI iOS app with an iOS 17+ deployment target. The app will keep goal data locally with SwiftData. Persistence must sit behind a repository interface so scheduling and planning can be tested without SwiftUI.

The core modules are:

- `GoalScheduler`: deterministic date math, default deadline selection, daily allocation, completion state, missed-day detection, and redistribution across remaining days.
- `GoalPlanningEngine`: converts user goal descriptions and scheduling context into structured daily checklist plans.
- `LocalLLMService`: wraps the `llama.cpp` integration and exposes a small async text-generation API.
- `ModelManager`: downloads, stores, verifies, and reports readiness for the selected GGUF model.
- `GoalRepository`: saves and loads goals, daily checklist items, model metadata, and completion history.

The scheduler owns timeline correctness. The LLM improves wording and decomposition, but it does not own dates, persistence, or completion math. This keeps the app predictable and testable.

## Model Management

The App Store binary should stay small, so the model downloads after install. The first-run experience shows model readiness and download progress. The default download is `Qwen/Qwen3-1.7B-GGUF`. A smaller `Qwen/Qwen3-0.6B-GGUF` path should be available if the default model cannot be downloaded or the device has limited free space.

Downloaded models are stored in the app support directory. The app validates the downloaded file before enabling planning. If model setup is incomplete, goal creation routes the user to model setup instead of failing silently.

## Prompt And Structured Output

The planning engine prompts the local model to produce compact JSON with a goal title, short rationale, and daily checklist templates. The model should output practical actions only. The app validates the JSON and normalizes it into internal models before saving.

Expected generated daily items are short, specific, and checkable. Examples:

- "Review 15 Spanish phrases."
- "Practice speaking aloud for 5 minutes."
- "Log one new phrase you used today."

If the model output is invalid, too long, unsafe, or unusable, the app falls back to a deterministic checklist built from the user's task description and the remaining time.

## UI And Components

The UI is calm, practical, and designed for daily repeated use. It should feel like a focused personal planning tool rather than a landing page.

Primary screens:

- `GoalDashboardView`: lists active goals and provides the new-goal entry point.
- `GoalCreationView`: collects task description, optional deadline, and starts generation.
- `GoalDetailView`: shows today's checklist, progress, timeline, and upcoming work.
- `ModelSetupView`: handles first-run model download and readiness.

Reusable components:

- `GoalCard`
- `DailyChecklistView`
- `ChecklistItemRow`
- `ProgressSummaryView`
- `DeadlinePicker`
- `ModelDownloadStatusView`

## Data Model

The internal data model should include:

- Goal: id, title, original description, created date, target date, status, progress summary, and selected model id.
- Daily plan: goal id, date, checklist items, completion state, and whether the day was rescaled.
- Checklist item: id, text, estimated effort label, completion state, completed date.
- Model metadata: model id, local file URL, download status, byte size, verification state.

Dates should be calendar-day based in the user's current calendar and time zone. The first version does not need account sync, cloud backup, social sharing, or cross-device collaboration.

## Rescaling Rules

When a day is missed, the app counts incomplete checklist items as remaining work. It redistributes that work across all days left before the target date. The redistribution should prefer small changes to future daily lists, preserving one to three checklist items per day when possible.

If the target date has passed, the app asks the user to extend the goal or mark it archived. It should not silently create an unrealistic same-day plan.

## Error Handling

Model download errors show retry and smaller-model options. Disk-space errors explain that the model needs local storage and provide the smaller model option. Interrupted downloads should resume when possible.

Inference errors do not block goal creation. If the LLM fails, times out, or returns invalid structured output, the app creates a simple deterministic plan and marks it as generated with fallback planning. The user can regenerate once the model is ready.

Persistence failures should show a clear error and avoid losing entered text. Goal creation should preserve the user's draft until save succeeds.

## Testing Strategy

Unit tests should cover:

- Default one-year deadline when no deadline is selected.
- User-selected deadline handling.
- Multiple active goals on the dashboard.
- Daily checklist generation normalization.
- Missed-day redistribution across remaining days.
- Completion state updates.
- Invalid LLM JSON fallback.
- Model-not-ready routing.
- Persistence round trips for goals and daily plans.

The LLM integration must be behind a protocol so tests use fixtures instead of running a real model. Scheduler tests should not depend on SwiftUI, the model runtime, or wall-clock time; tests should inject fixed dates.

## Implementation Boundaries

The MVP does not include cloud accounts, remote inference, subscriptions, ads, social sharing, watchOS support, notifications, widgets, or calendar integration. These are intentionally out of scope for the first local planning loop.

The first version should prioritize a working offline planning loop: download model, create goals, generate daily checklists, mark daily progress, and rescale missed work.
