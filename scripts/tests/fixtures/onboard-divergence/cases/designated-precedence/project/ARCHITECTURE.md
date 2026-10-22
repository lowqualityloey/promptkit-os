# Architecture
Event dispatch MUST be synchronous and in-process; no external queue is permitted.
Domain boundaries are owned by the workspace service.
