# I reopened my master's thesis after three years and found three of my own mistakes

*Draft for lucabontempi.com — September 2026. Every figure and every number below is produced
by a script in the [review repository](https://github.com/lucabnt/mobile-app-download-determinants-update).*

---

In February 2023 I submitted a thesis on a narrow question: when someone lands on an app's
product page in a store, which element of that page makes them decide to install it? I tested
three of them — the **average review rating**, the **number of downloads**, and the
**developer's brand**, carried by the app name, the icon and the developer's own name. I
manipulated screenshots of a real Play Store page, showed three of them to each of 491
respondents, and measured what the literature calls intention to download.

The answer I published was that the developer's brand is the most decisive element. Reputation
comes second. Popularity does essentially nothing.

This year I reopened the files. The data survived the scrutiny: the randomization worked, there
are no missing values, and every regression in the thesis reproduces to four decimal places. The
analysis did not. I made three mistakes, and none of them was in the data — they were in what I
did with it.

## Mistake one: I compared numbers that had never been compared

The headline finding came from placing three coefficients side by side: 1.53 for brand, 0.50 for
reputation, 0.36 for popularity. Brand is visibly the largest. Case closed.

Except that those three numbers came from three *different* regressions, estimated on three
*different* groups of respondents. Nowhere in the thesis is there a test of whether 1.53 differs
from 0.50. I looked at them and concluded.

So I ran the test I should have run. One model, all 1,473 answers, with a proper adjustment for
the fact that each person answered three times:

| Element | Effect on intention to download (1–7 scale) | 95% CI |
|---|---|---|
| Developer's brand | **+1.05** | 0.81 to 1.29 |
| Reputation (rating) | **+0.84** | 0.60 to 1.08 |
| Popularity (downloads) | +0.22 | −0.02 to 0.46 |

Brand and reputation are **not distinguishable** (p = 0.22). Both clearly beat popularity. My
three-step hierarchy is really two steps.

The interesting part is what the fragmentation cost. Splitting one sample into nine subsamples
threw away most of the statistical power I had collected — and reputation's effect rose by two
thirds, from 0.50 to 0.84, once it was estimated from all 491 answers rather than 149.

> **[FIGURE — `fig_05_pooling_gain.png`]**
> *Suggested caption: the same question asked two ways. Hollow points are the thesis estimates,
> each from its own subsample; solid points use all the data at once. Reputation rises by two
> thirds; brand moves the other way.*

To be sure this was not simply my new favourite model talking, I re-ran the comparison every
defensible way: 24 combinations of sample, model type and controls, one of which failed to
converge and was dropped. Brand comes out ahead in 4 of the remaining 23. The original conclusion
was not a finding about apps. It was an artefact of an analytical choice.

> **[FIGURE — `fig_04_specification_curve.png`]**
> *Suggested caption: every defensible specification of the same comparison. If a conclusion only
> appears in a corner of this picture, it is a choice, not a result.*

## Mistake two: my "manipulation check" was not one

The result people quoted back to me was the counter-intuitive one: download counts do not matter.
In a market where everybody watches install numbers, that is an enjoyable thing to say.

I no longer believe the data supports it, for two reasons I should have caught in 2022.

The first is embarrassing. I went back to the stimulus images themselves. The low-popularity
version of the app displays **10,000+ downloads alongside 84,000 reviews**. More reviews than
downloads. It is impossible, and the review count was held constant across the two conditions, so
the defect sits entirely in the weak version — precisely the one that had to carry the
comparison.

The second is subtler. The thesis reports a manipulation check: the share of respondents who
confirmed they had noticed each element. What I actually asked, once, at the very end, was *which
factors did you take into consideration?*, with nine boxes to tick. That is not a check that the
manipulation registered. It is people reporting, after the fact, what they believe they did.
Among the 60% who ticked "number of downloads", the popularity effect more than doubles, to +0.51,
and becomes significant — but that comparison is close to circular, because people moved by
download counts are more likely to say they looked at them.

So what is the honest answer? Before looking, I fixed the smallest effect that would matter in
practice. Every reasonable way of deriving it lands between 0.26 and 0.33 scale points. Measured
against that bar:

- **before comparison**, when a respondent sees one app and nothing else, popularity does work:
  +0.46, and that one is real;
- **after** they have seen other apps, the effect is +0.06, sitting exactly on the boundary of
  what this study can resolve. I cannot separate "nothing" from "too small to matter".

> **[FIGURE — `fig_07_equivalence.png`]**
> *Suggested caption: which null results are really null. The shaded band is the zone of
> practical irrelevance, fixed before the tests were run. An interval far wider than the band
> means the study could not see, not that there was nothing to see.*

"Download counts do not matter" was too strong. "Download counts are the cue you fall back on
when you have nothing else to go on" fits everything I can observe.

## Mistake three: I reported absence where I should have reported blindness

The thesis concludes that there is no interaction between the three elements — a strong rating
does not amplify a strong brand, and so on. That is true in the sense that nothing came out
significant.

It is also empty. Running the numbers, my design could only have detected an interaction larger
than roughly 1.3 points on the 7-point scale, about 0.9 standard deviations. Real interactions in
this literature are fractions of the main effects, which here range from 0.2 to 1.0. I was
searching for something my instrument could not see, and reporting the silence as evidence.

The same applies to two moderation results on which I built managerial advice. Neither replicates,
and neither can be ruled out either. Of the 81 coefficients I estimated across nine regressions,
exactly **two** survive a correction for having run that many tests. Both are the brand effect.

## What holds up — and one thing that is new

**Brand and reputation are equally powerful, and interchangeable only on average.** Split by
position in the sequence, the picture is sharper than anything I originally claimed:

| | Shown first | Shown after other apps |
|---|---|---|
| Developer's brand | **+1.41** | +0.90 |
| Reputation | +0.69 | **+0.91** |
| Popularity | +0.46 | +0.06 |

> **[FIGURE — `fig_06_by_position.png`]**
> *Suggested caption: the ranking depends on where the app appears in the sequence. Brand
> dominates the first app seen and fades; reputation holds steady and overtakes it.*

Brand dominates when there is nothing to compare against. Once a user has seen alternatives, the
two converge completely. Stated as a probability: the brand leads reputation with 99% probability
before comparison, and 51% after — a coin toss.

> **[FIGURE — `fig_13_posterior.png`]**
> *Suggested caption: how large each effect plausibly is, given the data. Where two curves
> overlap, the data cannot tell the two elements apart — which is what "not distinguishable"
> looks like.*

There is a practical reading. A strong brand is worth most in the moment when the user is not
shopping around: a link from a search result, an advertisement, a recommendation. Ratings earn
their keep in the browse-and-compare context, where the user is actively collecting information.
For a new entrant this is better news than it sounds. You cannot buy Adobe's brand, but you can be
the app that survives the comparison.

And one genuinely new finding, which I had predicted in writing would fail before I ran it:
**respondents differ a great deal in how much any of this moves them**, and the difference is
systematic. The people most inclined to download things in general are the *least* moved by what
the listing shows (correlation −0.61). The cues do their work on the undecided. An average effect
across everybody conceals that entirely.

> **[FIGURE — `fig_08_heterogeneity.png`]**
> *Suggested caption: each dot is one respondent — their baseline enthusiasm against how much the
> page elements move them. The cues work on the undecided.*

## Three things I checked that changed nothing

A reanalysis is only worth as much as the checks that could have embarrassed it. Three of them
did not.

Respondents do not treat a 1–7 scale as a ruler. The step into the top category is nearly twice
the step into the third, because people avoid the ends of a scale. Re-estimating everything
without assuming even spacing moves the effects by 0.8 to 3.1 percentage points and leaves the
ranking untouched.

The effects do not depend measurably on who is answering — not on age, gender, education or
occupation. Students respond to reputation roughly twice as strongly as employed respondents,
which is a tidy story that does not pass its own test; with 69% students in the sample, it could
not have passed.

And removing the 33 respondents who rushed or gave a single answer to an entire scale moves every
effect slightly upwards, as removing noise should, and changes nothing else.

> **[FIGURE, optional — `fig_09_scale_cutpoints.png`]**
> *Suggested caption: where each answer boundary sits on the underlying intention scale, against
> what an evenly spaced scale would look like.*

> **[FIGURE, optional — `fig_12_demographics.png`]**
> *Suggested caption: the effect of each element by occupation. A coherent pattern that does not
> pass its own test.*

## What three years of distance taught me

Three things, none of them about app stores.

**Splitting a sample to answer a question is usually the wrong move.** My nine separate
regressions discarded most of the power I had collected, and then left me comparing numbers
across samples that could not be compared. One model on all the data answered the question
directly, and gave a different answer.

**"Not significant" is not a finding until you say what you could have detected.** Every null
result I reported deserved a sentence about the smallest effect the design could see. Three of
them dissolve under that question.

**Look at your stimuli again.** The worst problem in this project — a screenshot showing more
reviews than downloads — was not in the models or in the data. It was in an image file I had
looked at a hundred times in 2022 and never actually checked.

---

*A note on how this was done.* The reanalysis was carried out with AI assistance, and the idea
began as a small curiosity: how would an AI have written my master's thesis? The answer turned out
to be less interesting than the question it provoked, which is how an AI would **review** it. It
did not find anything I could not have found myself in 2023. It did the one thing I did not do,
which is to check every claim against the evidence I already had, including the claims that were
convenient. That is a low bar, and I did not clear it the first time.

*The full review, the reanalysis code, the decision rules fixed before the tests were run, and
every log are in the
[review repository](https://github.com/lucabnt/mobile-app-download-determinants-update). The
original thesis, data and code remain
[here](https://github.com/lucabnt/mobile-app-download-determinants). Further figures — on the
answer scale, on respondent demographics, on response quality and on order effects — are in the
repository for anyone who wants them.*
