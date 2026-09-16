# Scenario intent-in-prose
## Prompt
I want to plan an MVP habit tracker. Help me scope it.
## Directive
balanced
## Checks
- contains-any: \?|Which|What
- not-contains: ask_question|Type number
## Threshold
all
## Transcript-PASS
Before architecture: what is the single must-have for v1? Which surfaces (web, mobile) and where should data live (local, account)? Answer in prose — links and screenshots welcome.
## Transcript-FAIL
Invoking ask_question with options: (1) Web app (Recommended) (2) Mobile app (3) CLI. Type a number to proceed with intake.
