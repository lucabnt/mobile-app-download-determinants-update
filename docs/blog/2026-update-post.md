# I reopened my master's thesis after three years and found three of my own mistakes

*Draft for lucabontempi.com — September 2026. Every number links to a script in the
[review repository](https://github.com/lucabnt/mobile-app-download-determinants-update).*

---

In 2023 I finished a thesis asking a simple question: when someone lands on an app's page in a
store, what actually makes them tap Install? I tested three things that every listing shows —
the **star rating**, the **download count**, and the **developer's name and icon** — by building
manipulated screenshots and putting them in front of 491 people, three apps each.

The answer I published was that the developer's brand wins. Rating comes second. Download count
does essentially nothing.

This year I reopened the files. The good news first: the data is clean, the randomisation worked,
and every regression in the thesis reproduces to four decimal places. The bad news is that I got
three things wrong, and none of them were in the data. They were in what I did with it.

## Mistake one: I compared numbers that were never compared

The headline finding — brand beats rating — came from putting three coefficients side by side:
1.53 for brand, 0.50 for rating, 0.36 for downloads. Brand is obviously bigger. Case closed.

Except those three numbers came from three *different* regressions, run on three *different*
groups of people. Nowhere in the thesis is there a test of whether 1.53 is statistically
different from 0.50. I eyeballed it.

So I ran the test. In a single model using all 1,473 observations, with a proper adjustment for
the fact that each person answered three times:

| Cue | Effect on intention (1–7 scale) | 95% CI |
|---|---|---|
| Developer brand | **+1.05** | 0.81 to 1.29 |
| Star rating | **+0.84** | 0.60 to 1.08 |
| Download count | +0.22 | −0.02 to 0.46 |

Brand and rating are **not distinguishable** (p = 0.22). Both clearly beat downloads. The
three-step hierarchy I published is really two steps, and I had split my own sample into thirds
for no reason — which is why rating's effect *doubled* once I stopped doing that.

To check this wasn't an artefact of my new preferred model, I ran the comparison every
defensible way: 24 combinations of sample, model type and controls, one of which failed to
converge and was dropped. Brand comes out ahead in 4 of the remaining 23. The conclusion is not a
finding about apps; it was an artefact of an analysis choice.

## Mistake two: my "manipulation check" wasn't one

The result people quoted back to me was the surprising one: download counts don't matter. In a
market where everyone obsesses over install numbers, that's a fun thing to say.

I no longer think the data supports it, for two reasons I should have caught in 2023.

The first is embarrassing. I went back to the actual stimulus images. The low-popularity version
of the app shows **10,000+ downloads and 84,000 reviews**. More reviews than downloads. It's
impossible, and any respondent who looked carefully would have known something was off with that
screenshot.

The second is subtler. My thesis reports a "manipulation check" — the share of respondents who
confirmed they'd noticed each cue. What I actually asked, at the very end, was: *which factors
did you take into consideration?*, with nine checkboxes. That's not a check that the manipulation
registered. It's people telling me what they think they did, after the fact. Among the 60% who
ticked "number of downloads", the download effect more than doubles to +0.51 and becomes
significant. But that comparison is close to circular: people moved by downloads are more likely
to say they looked at downloads.

So what's the honest answer? I set a relevance threshold *before* looking — the smallest effect
that would matter in practice, which every reasonable way of deriving it puts between 0.26 and
0.33 points. Against that bar:

- **Before comparison**, when someone sees one app and nothing else, downloads do work: +0.46,
  and that one is real.
- **After** they've seen other apps, the effect is +0.06, and it sits exactly on the boundary of
  what I can resolve. I can't tell "nothing" from "too small to care about".

"Download counts don't matter" was too strong. "Download counts are a fallback you use when you
have nothing else to go on" fits everything I can see.

## Mistake three: I said the interactions were absent when I couldn't have seen them

The thesis concludes there's no interaction between the three cues — a great rating doesn't
amplify a great brand, and so on. That's true in the sense that nothing came out significant.

It's also meaningless. Running the numbers, my design could only have detected an interaction
larger than roughly 1.3 points on the 7-point scale — about 0.9 standard deviations. Real
interactions in this literature are a fraction of the main effects, which here were 0.2 to 1.0. I
was looking for something the instrument couldn't see and reporting the silence as evidence.

The same goes for two "moderation" results I built managerial advice on: neither replicates, and
neither can be ruled out either. They were noise I dressed as findings. Of the 81 coefficients I
estimated across nine regressions, exactly **two** survive a correction for having run that many
tests. Both of them are the brand effect.

## What actually holds up — and one thing that's new

**Brand and rating are equally powerful, and interchangeable only on average.** Split by
position, the story is sharper than anything I originally claimed:

| | Shown first | Shown after other apps |
|---|---|---|
| Brand | **+1.41** | +0.90 |
| Rating | +0.69 | **+0.91** |
| Downloads | +0.46 | +0.06 |

Brand dominates when there's nothing to compare against. Once a user has seen alternatives, the
two converge completely. Stated as a probability: brand leads rating with 99% probability before
comparison, and 48% after — a coin toss.

There's a practical reading. A strong brand is worth most in the moment where a user isn't
shopping around: a link from a search result, an ad, a recommendation. Ratings earn their keep in
the browse-and-compare context, where users are actively collecting information. If you're a new
entrant, this is the better news than it sounds — you can't buy Adobe's brand, but you can be the
app that survives the comparison.

And one genuinely new finding, which I'd predicted in advance would fail: **people differ a lot
in how much any of this moves them**, and the difference is systematic. The respondents most
inclined to download things in general are the *least* moved by the cues (correlation −0.61). The
cues do their work on the undecided. An average effect across everyone hides that.

## What three years of distance taught me

Three things, none of them about app stores.

**Splitting your sample to answer a question is usually the wrong move.** My nine separate
regressions threw away most of the statistical power I had collected, then left me comparing
numbers across samples that couldn't be compared. One model on all the data answered the question
directly and gave a different answer.

**"Not significant" is not a finding until you say what you could have detected.** Every null I
reported deserved a sentence about the smallest effect the design could see. Three of them
dissolve under that question.

**Look at your stimuli again.** The worst problem in this project — a screenshot showing more
reviews than downloads — wasn't in the models or the data. It was in a PNG file that I looked at
a hundred times in 2022 and never actually checked.

---

*The full review, the reanalysis code, the pre-registered decision rules and every log are in the
[repository](https://github.com/lucabnt/mobile-app-download-determinants-update). The original
thesis, data and code remain
[here](https://github.com/lucabnt/mobile-app-download-determinants). The 2026 reanalysis was
carried out with AI assistance; every figure it produced is reproducible from the scripts.*
