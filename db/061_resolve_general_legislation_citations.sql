-- =============================================================================
-- Resolve general (state-level) open_issues #2 and #3 via direct lookup
-- against legislation.qld.gov.au (both freely reachable, unlike the
-- HIGH-severity ePlan/QHC-register sites). Pure citation confirmation --
-- neither changes any currently-encoded rule's value or scope.
-- =============================================================================
SET search_path = regs, public;

-- #2: former Building Regulation 2021 s6 text, confirmed against the
-- 10 March 2025 in-force version (its final wording before repeal by the
-- Building and Other Legislation Amendment Regulation 2026, SL No. 115):
--   "(1) This section applies ... for a single detached class 1 building,
--   and for a class 10 building or structure located on the same allotment
--   ... (2) A local government's planning scheme may provide for (a) all
--   or some of performance criteria 4, 5, 7, 8 or 9 under QDC part 1.1 ...
--   (b) all or some of performance criteria 4, 5, 7 or 8 under QDC part
--   1.2 ... where the scheme does, the acceptable solutions for those
--   criteria apply to the building work; (c) a qualitative statement for a
--   matter under those criteria, only if quantifiable standards are also
--   provided (meanings per Building Act 1975 s33(6))."
-- This matches Brisbane City Plan Table 1.6.1 item 6's own citation
-- ("Section 32(b) BA and section 6 BR ... performance criteria 4 under QDC
-- parts MP 1.1 and MP 1.2 for a single detached class 1 building or a
-- class 10 building or structure located on the same allotment") almost
-- verbatim -- City Plan's item 6 designation is confirmed as a valid
-- exercise of this power. No rule changes needed.
UPDATE open_issues
SET resolved_at = CURRENT_DATE
WHERE issue_id = 2;

-- #3: the current Planning Regulation 2017 referral item succeeding
-- Sustainable Planning Regulation 2009 Sch 7 Item 27A is Schedule 9, Part
-- 3, Division 3, Table 7 ("Building work over or near relevant
-- infrastructure relating to Queensland Development Code, part 1.4"),
-- confirmed live against legislation.qld.gov.au -- the table's own trigger
-- names "Queensland Development Code, part 1.4" explicitly, i.e. QDC MP
-- 1.4 (db/010: 'QDC MP 1.4 - Building over or near relevant
-- infrastructure'). Referral agency: "the relevant service provider".
-- This is a referral-agency/jurisdiction question for MP 1.4 infrastructure
-- clearance, not a Class 10a siting setback -- confirming it doesn't change
-- any rule this tool outputs, just the citation.
UPDATE open_issues
SET resolved_at = CURRENT_DATE
WHERE issue_id = 3;
