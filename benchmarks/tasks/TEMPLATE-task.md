# Task Spec: [Short task title]

<!-- One file per benchmark task. Fields are single-line and grep/awk-parseable;
     the driver reads the Task ID, Level, Prompt, and optional Setup lines
     verbatim. The Rubric is FROZEN before any run: it is the blind grader's
     entire scoring instrument, so each item must be observable from the
     stripped diff and the run log alone. No rubric edits after the first run
     of the task — supersede the file with a new Task ID instead.

     Verify convention (required whenever a rubric item needs execution
     proof): ONE line, behavioral probe FIRST, test suite SECOND, non-zero if
     either fails —

       <probe>; probe=$?; node --test; tests=$?; \
         printf 'VERIFY|probe=%s|tests=%s\n' "$probe" "$tests"; \
         [ "$probe" -eq 0 ] && [ "$tests" -eq 0 ]

     Joining probe and suite with && is a defect, not a style choice: the
     suite then short-circuits the probe, the packet holds only test output,
     and every rubric item that depends on behavior becomes ungradeable while
     verify_exit reports the suite's opinion alone. Run the probe first so its
     output leads B<nnn>.verify.txt, always run the suite after it, print the
     VERIFY| line so a silent probe or suite still states its status, and let
     the command's exit status mean "both passed". Name in Notes the defect
     the probe is meant to catch, and make each assertion it makes explicit in
     the prompt or a rubric item — a probe may not require something the
     grader cannot find stated. -->

- **Task ID**: `BENCH-<LEVEL>-<NN>` <!-- stable scenario id used in §5 records -->
- **Level**: `L0 | L1 | L2 | L3` <!-- per the canonical task-ceremony scale -->
- **Seed Repository**: `[path or URL of the seed repo this task runs against]`
- **Prompt**: `"[The verbatim user prompt the agent receives in BOTH arms — byte-identical, single line]"`
- **Setup**: `[Optional shell command run in the fresh run directory after clone and BEFORE the agent starts (same in both arms), or None]`
- **Verify**: `[Optional single-line command the HARNESS runs post-session in the run directory to produce arm-neutral verification evidence (B<nnn>.verify.txt) for rubric items that need execution proof, or None. Follow the probe-first shape in the header comment: <probe>; probe=$?; node --test; tests=$?; printf 'VERIFY|probe=%s|tests=%s\n' "$probe" "$tests"; [ "$probe" -eq 0 ] && [ "$tests" -eq 0 ]]`

## Rubric

<!-- Each item is checked by the blind grader from the stripped diff, plus the
     harness-produced B<nnn>.verify.txt when the task declares a Verify command.
     NEVER grade from session logs — they contain scenario names and arm-revealing
     output. Weight is equal per item unless stated; the grading sheet records
     passed/total. -->

- [ ] `R1`: [Observable acceptance condition]
- [ ] `R2`: [Observable acceptance condition]
- [ ] `R3`: [Observable acceptance condition]

## Notes

- [Anything the grader needs: relevant files, expected shape of the change,
   known traps. No hints about implementation the prompt doesn't give.]
