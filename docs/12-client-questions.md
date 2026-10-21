# Questions for the client — inputs for the Class 10a and pool setback check

Our inputs are: address, structure type, width, length and height. The rules we hold (QDC MP 1.1 / 1.2, QHC and the
seven council planning schemes) also depend on a few facts those inputs do not give. Each question below says
what the rule needs, the options, and what we recommend. Questions are in priority order: 1–5 change the setback
answer for most properties.

---

## 1. Front setback where the neighbours' houses sit closer to the street (QDC A1(a))

**What the rule says.** QDC MP 1.2 A1(a), lots of 450 m² or more, applies to a **dwelling, garage or carport**. The
minimum road setback is:

| Option | When it applies | Front setback |
|---|---|---|
| (i) | Always available | **6 m** |
| (ii)(A) | Houses on **both** neighbouring lots, at least one set back 3–6 m, and their setbacks differ by **2 m or less** | Anywhere **between** the two neighbours' setbacks |
| (ii)(B) | As above, but their setbacks differ by **more than 2 m** | The **average** of the two neighbours' setbacks |

On lots under 450 m² (MP 1.1), option (i) is 3 m or 4 m by street type (see question 4). There is also an option
(iii): if both neighbours are 3 m or less from the street, anywhere between them. In MP 1.1 the neighbour options
apply to the **house only**.

**Example.** The neighbours are at 4.0 m and 5.5 m (1.5 m apart): a carport could sit anywhere from 4.0 m to 5.5 m,
instead of 6 m. If they are at 3.5 m and 6.0 m (2.5 m apart), the minimum is the average, 4.75 m.

**Who it affects.** Garages and carports only. It never applies to sheds, patios, pergolas, decks or pools: they
always use the standard setback (6 m; pools 1.5 m).

**Question.** For garages and carports, should we:
* **A.** Always show 6 m, with a note that it *may* reduce to match the neighbours *(no extra input)*;
* **B.** Add an optional input, "front setbacks of the two neighbouring houses", and calculate the reduced value
  when it is given; or
* **C.** Estimate the neighbours' setbacks automatically from building-footprint map data? This is less reliable
  and must be confirmed on site.

*Recommendation: A by default, plus B as an optional field.*

## 2. Building a shed or garage on the side or rear boundary (QDC A2(d))

**What the rule says.** The normal side and rear clearance is 1.5 m for a structure up to 4.5 m high. A Class 10a
structure may be built **closer, up to the boundary (0 m)**, only if all of these hold:
* the part within 1.5 m is **no more than 4.5 m high** and **no more than 3.5 m mean height**;
* **all** buildings within the clearance along that boundary, including the house, total **no more than 9 m**; and
* it is **at least 1.5 m from a habitable-room window** of the neighbour's house.

The last two cannot be known from width, length and height alone.

**Question.** Should we:
* **A.** Show "1.5 m — or 0 m if [conditions]" and let the user decide;
* **B.** Ask two yes/no questions: "Is there any other building within 1.5 m of this boundary?" and "Is a
  neighbour's window within 1.5 m?"; or
* **C.** Show only 1.5 m, the conservative value?

*Recommendation: B. It is two clicks, and most customers want the shed on the boundary.*

**Related.** For a pool, the same 1.5 m clearance can only be reduced if there is a solid wall or fence at least
1.8 m high between the pool and the boundary, rising at least 1.0 m above the pool coping (A2(e)). Should we ask
whether one exists, or always show 1.5 m for pools?

## 3. Where on the lot will the structure go?

Setbacks differ by boundary (front, side, rear). Some rules also depend on whether the structure is **in front
of the house** (Moreton Bay outbuildings, Brisbane character areas) or **attached to the house** (7 council rules:
attached patios and carports follow the house setbacks).

**Question.** Will the user:
* **A.** Get the limits for every boundary and place the structure themselves on the site plan; or
* **B.** Tell us where the structure goes (front / side / rear, attached or detached), so we show only the
  relevant setback?

*Recommendation: A for the output, plus one yes/no input: "attached to the house?".*

## 4. Small lots (under 450 m²): what type of street is it?

QDC MP 1.1 sets the front setback by street type: **3 m** on an access street or access place, **4 m** on a
collector street. Street type is not in public map data for most councils.

**Question.** Should we:
* **A.** Default to 4 m (conservative), labelled "assumed"; or
* **B.** Ask the user to choose the street type?

*Recommendation: A, with B as an optional override.*

## 5. What exactly is "height"?

The rules use three different heights:
* **overall height**, for the maximum-height limit;
* **height of the part near the boundary**, for side and rear clearances;
* **mean height of the wall facing the boundary**, for the 3.5 m built-to-boundary limit.

On a gable-roof shed, mean height is about halfway between eave and ridge.

**Question.**
* Is the one height input the **ridge (top) height**?
* May we use it for all three? That is conservative, but a 4 m ridge with a 2.7 m eave would wrongly fail the
  3.5 m mean-height test.
* Or should we also ask for **wall / eave height**?
* For pools, is height the **coping height above ground**? The 1.5 m pool setback assumes coping ≤ 1.2 m.

*Recommendation: ridge height plus an optional eave height. Pools: coping height.*

---

## 6. Site cover: limit only, or "how much is left"?

We can always give the limit (e.g. 50 % of 600 m² = 300 m²). Whether the new structure fits depends on the
roofed area already on the lot: the house, existing sheds and patios. Logan's large-shed setbacks also depend on
the **total** shed floor area, existing plus new (over 150 m²: 6 m side and rear).

**Question.** Should we:
* **A.** Show the limit only;
* **B.** Ask for the existing roofed area; or
* **C.** Estimate it from building-footprint map data, which the user can correct?

Should uncovered pools be excluded from site cover? QDC counts roofed areas only.

## 7. Corner lots and which street is "the front"

On a corner lot both streets need a road setback. Under QDC, the council can nominate which one is the primary
frontage. We can detect corner lots from the cadastre, but not always which frontage is primary.

**Question.** Should we auto-detect and show both frontages, or ask the user to confirm the primary street?

## 8. Waterfront and sloping lots

* **Canals and lakes.** Is waterfront property in scope? If so, auto-detect it or ask the user? The rules:
  * Redland (LDR5): **9 m** from canals and lakes, including outbuildings.
  * Sunshine Coast: **4.5 m** from canals and artificial waterways, for structures over 1 m high, including pools
    and decks.
* **Slopes.** On land steeper than 15 %, the height limit rises:
  * QDC: 8.5 m → 10 m.
  * QHC: Class 10a 4.5 m → 6 m.

  Should we ask for slope, estimate it from elevation data, or assume flat? Assuming flat is conservative.
* **Note on height after the QHC.** Once a council adopts the Queensland Housing Code, the maximum height for a
  Class 10a structure drops from 8.5–9.5 m to **4.5 m**. Taller sheds will then need approval, which users should
  be warned about.

## 9. When a rule is unclear or council-specific, what should the user see?

Some answers cannot be certain: a council wording ambiguity, or a fact we had to assume.

**Question.** For these cases, should we:
* **A.** Show the **conservative** value with a clear "assumed — confirm" label; or
* **B.** Show "needs checking" with no number?

*Recommendation: A, because a site plan needs a number.*

**Known example.** On the **Gold Coast** (Low density and Rural residential zones), the planning scheme sets its
own side and rear setbacks and is silent on whether the QDC built-to-boundary concession (question 2) still
applies to sheds. May we put this one question to Gold Coast City Council or a certifier on your behalf? Until
then we would show the scheme's setback without the 0 m option.

## 10. Scope confirmation

Please confirm these are **out of scope**:
* sewer and water-main clearances (QDC MP 1.4; we would show a warning only);
* pool fencing (MP 3.4);
* overlays other than character overlays (flood, bushfire, heritage, coastal);
* whether planning approval is needed.

Please also confirm the **assessment date**: should results always use today's rules, or may the user pick a date?
A date matters when a council adopts the Queensland Housing Code mid-project.
