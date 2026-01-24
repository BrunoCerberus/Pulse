# ``Pulse``

A modern iOS news aggregation app built with Unidirectional Data Flow Architecture.

## Overview

Pulse fetches news from a Supabase backend (with Guardian API fallback) and presents
articles in a clean SwiftUI interface. Premium features include AI-powered summaries
and personalized feeds using on-device LLM inference.

### Features

- **Home**: Breaking news carousel and headline feeds with infinite scroll
- **For You**: Personalized feed based on followed topics (Premium)
- **Feed**: AI-powered Daily Digest summarizing recent reading (Premium)
- **Search**: Full-text search with autocomplete and sort options
- **Bookmarks**: Save articles for offline reading
- **Summarization**: On-device AI article summarization (Premium)

### Architecture

Pulse uses a Unidirectional Data Flow (UDF) architecture based on Clean Architecture principles:

```
View (SwiftUI)
    ↓ handle(event: ViewEvent)
ViewModel (CombineViewModel)
    ↓ dispatch(action: DomainAction)
DomainInteractor (CombineInteractor)
    ↓
Service Layer (Protocol-based)
    ↓
Network/Storage
```

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:Architecture>

### Core Protocols

- ``CombineViewModel``
- ``CombineInteractor``
- ``ViewStateReducing``
- ``DomainEventActionMap``
- ``ServiceLocator``

### Navigation

- ``Coordinator``
- ``Page``
- ``NavigationRouter``

### Services

- ``NewsService``
- ``SearchService``
- ``StorageService``
- ``AuthService``
- ``StoreKitService``
- ``FeedService``
- ``LLMService``
