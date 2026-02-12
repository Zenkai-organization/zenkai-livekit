# Plan: Customizable Interview Questions from Frontend

## 🎯 Objective
Enable frontend to send custom interview questions to backend agent instead of using hardcoded questions, allowing dynamic interview configuration per call.

## 📋 Current State Analysis

### Backend Issues
- Questions are hardcoded in `InterviewState.get_next_question()` in `agent-starter-python/src/agent.py`
- No mechanism to receive custom questions from frontend
- Fixed 3-question limit

### Frontend Opportunities
- Frontend can send `room_config` with agent metadata via connection token
- LiveKit supports room metadata that persists throughout session
- Backend can access `ctx.room.metadata` after connecting

## 🚀 Implementation Strategy

### Option 1: Room Metadata (Recommended)
**Flow:** Frontend → Room Config → LiveKit Token → Room Metadata → Backend Agent

**Benefits:**
- Built into LiveKit architecture
- Persists throughout session
- Backwards compatible
- Clean separation of concerns

### Option 2: Participant Attributes (Alternative)
**Flow:** Frontend → Participant Attributes → Backend Agent

**Considerations:**
- More complex to manage
- Limited size per attributes
- Less discoverable

## 📅 Implementation Phases

### Phase 1: Frontend Interface Extensions

#### 1.1 Extend AppConfig Interface
**File:** `agent-starter-react/app-config.ts`
**Changes:**
```typescript
export interface AppConfig {
  // ... existing fields
  questions?: string[];  // Custom interview questions
  interviewType?: 'behavioral' | 'technical' | 'management' | 'custom';
}
```

#### 1.2 Create Question Editor Component
**File:** `agent-starter-react/components/app/question-config.tsx`
**Features:**
- Add/Edit/Delete questions
- Reorder questions (drag & drop)
- Question validation
- Import/export question sets
- Preset templates for different interview types

#### 1.3 Update Token Generation Logic
**File:** `agent-starter-react/lib/utils.ts` - `getSandboxTokenSource()`
**Changes:**
```typescript
const roomConfig = appConfig.agentName
  ? {
      agents: [{ 
        agent_name: appConfig.agentName,
        metadata: JSON.stringify({ 
          questions: appConfig.questions || [],
          interviewType: appConfig.interviewType || 'custom'
        })
      }],
    }
  : undefined;
```

#### 1.4 Enhance Welcome View
**File:** `agent-starter-react/components/app/welcome-view.tsx`
**Changes:**
- Add "Configure Questions" button
- Show current question count
- Preview questions before call
- Access question editor modal

### Phase 2: Backend Dynamic Questions

#### 2.1 Modify InterviewState Class
**File:** `agent-starter-python/src/agent.py`
**Changes:**
```python
class InterviewState:
    def __init__(self, custom_questions=None):
        self.current_question = 0
        self.scores = []
        self.answers = []
        self.questions = custom_questions or self._get_default_questions()
        self.total_questions = len(self.questions)
    
    def _get_default_questions(self):
        return [
            "Tell me about a time when you had to work with a difficult team member...",
            "Describe a project you're most proud of...",
            "How do you handle tight deadlines and multiple priorities..."
        ]
```

#### 2.2 Extract Questions from Room Metadata
**File:** `agent-starter-python/src/agent.py` - `my_agent()` function
**Changes:**
```python
@server.rtc_session(on_request=on_request)
async def my_agent(ctx: JobContext):
    # Extract custom questions from room metadata
    custom_questions = []
    if ctx.room.metadata:
        try:
            import json
            metadata = json.loads(ctx.room.metadata)
            if "questions" in metadata:
                custom_questions = metadata["questions"]
                logger.info(f"Loaded {len(custom_questions)} custom questions")
        except (json.JSONDecodeError, KeyError) as e:
            logger.warning(f"Failed to parse questions from room metadata: {e}")
    
    # Initialize interview state with custom questions
    interview_state = InterviewState(custom_questions)
    current_agent = Assistant(interview_state)
```

#### 2.3 Update Question Access Logic
**File:** `agent-starter-python/src/agent.py`
**Changes:**
```python
def get_next_question(self) -> str:
    if self.current_question < len(self.questions):
        return self.questions[self.current_question]
    return ""
```

#### 2.4 Dynamic Question Count
**File:** `agent-starter-python/src/agent.py` - `start_interview_flow()` function
**Changes:**
```python
await session.say(
    f"Welcome to interview! I'll ask you {interview_state.total_questions} questions. Let's begin with the first one: {first_question}"
)
```

### Phase 3: Enhanced User Experience

#### 3.1 Question Templates System
**File:** `agent-starter-react/lib/question-templates.ts`
**Templates:**
- Behavioral Interview (3 questions)
- Technical Interview (5 questions)
- Management Interview (4 questions)
- Customer Service Interview (3 questions)
- Custom (user-defined)

#### 3.2 Question Editor Features
- **Question Management:**
  - Add new question
  - Edit existing question
  - Delete question
  - Reorder via drag & drop
  
- **Validation Rules:**
  - Minimum 1 question
  - Maximum 10 questions
  - Question length limits
  - Required field validation

- **Import/Export:**
  - Save question sets to local storage
  - Load from JSON files
  - Share question sets via URL parameters

#### 3.3 Enhanced Welcome View Integration
- Show interview type selector
- Display question preview
- "Advanced Configuration" for templates
- "Quick Start" with default questions

### Phase 4: Advanced Features

#### 4.1 Question Categories
```typescript
interface Question {
  id: string;
  text: string;
  category: string;
  weight?: number; // For scoring priority
  followUp?: string[]; // Additional questions based on answers
}
```

#### 4.2 Conditional Question Logic
- Skip questions based on previous answers
- Branch to different question sets
- Follow-up questions based on key responses

#### 4.3 Scoring Customization
- Custom scoring criteria per question
- Weighted scoring for different question types
- Custom feedback templates

#### 4.4 Question Analytics
- Track question effectiveness
- Average response length
- Common score ranges
- Question difficulty analysis

## 🔧 Technical Implementation Details

### Data Structure
```typescript
// Frontend Question Structure
interface InterviewConfig {
  questions: string[];
  interviewType: 'behavioral' | 'technical' | 'management' | 'custom';
  scoringCriteria?: {
    excellent: number; // 8-10 range
    good: number;      // 5-7 range
    needsWork: number;  // 1-4 range
  };
}
```

### Room Metadata Flow
```typescript
// Frontend sends
{
  "questions": [
    "Describe your experience with...",
    "How do you handle..."
  ],
  "interviewType": "custom"
}

// Backend receives
ctx.room.metadata = JSON.stringify(above_object)
```

### Error Handling
- **Metadata parsing errors:** Fallback to default questions
- **Invalid question format:** Validate and show user-friendly errors
- **Empty question list:** Prevent interview start
- **Network failures:** Cache questions locally

## 📊 Success Metrics

### Functional Requirements
- ✅ Frontend can customize questions per call
- ✅ Backend dynamically receives and uses custom questions
- ✅ Backwards compatibility with hardcoded questions
- ✅ Question validation and error handling
- ✅ Persistent storage of question sets

### User Experience
- ✅ Intuitive question editor interface
- ✅ Quick templates for common interview types
- ✅ Real-time preview of questions
- ✅ Import/export capabilities

### Technical Quality
- ✅ Type safety with TypeScript interfaces
- ✅ Proper error boundaries and validation
- ✅ Clean separation of concerns
- ✅ Scalable architecture for future features

## 🚦 Risk Mitigation

### Potential Issues
1. **Room metadata size limits:** Compress questions if needed
2. **JSON parsing errors:** Robust error handling with fallbacks
3. **Question validation:** Frontend and backend validation
4. **Backwards compatibility:** Maintain default question behavior

### Mitigation Strategies
- Question size monitoring and warnings
- Try-catch blocks with logging
- Validation on both frontend and backend
- Feature flags for gradual rollout

## 📝 Files to Modify

### Frontend Files
- `agent-starter-react/app-config.ts` - Add questions field
- `agent-starter-react/components/app/question-config.tsx` - New component
- `agent-starter-react/components/app/welcome-view.tsx` - Add config UI
- `agent-starter-react/lib/utils.ts` - Update token generation
- `agent-starter-react/lib/question-templates.ts` - New templates file

### Backend Files
- `agent-starter-python/src/agent.py` - Dynamic questions support
- `agent-starter-python/tests/test_agent.py` - Update tests

## 🎯 Next Steps

1. **Phase 1 Implementation:** Frontend interfaces and question editor
2. **Phase 2 Implementation:** Backend dynamic question handling
3. **Phase 3 Implementation:** Enhanced UX and templates
4. **Testing:** Comprehensive end-to-end testing
5. **Documentation:** Update README and examples
6. **Deployment:** Roll out feature with feature flags

## 📚 References

- [LiveKit Room Metadata](https://docs.livekit.io/home/client/state/room-metadata)
- [LiveKit Agent Dispatch](https://docs.livekit.io/agents/server/agent-dispatch/)
- [React Hook Patterns](https://react.dev/learn/reusing-logic-with-custom-hooks)
- [TypeScript Interface Design](https://www.typescriptlang.org/docs/handbook/2/objects.html)