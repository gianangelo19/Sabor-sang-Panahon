# Box Unboxing dialogue plan

The speaker is the MC talking to himself. Item descriptions are shown when an
item is first investigated and whenever its History row is selected.

| Trigger | Expression | Dialogue / behavior |
| --- | --- | --- |
| Old newspaper | Concerned | “A torn newspaper... La Paz, hot broth, and miki are still readable. The dish's name is missing.” |
| Family photo | Happy | “Lola looks so happy here. This photo feels warm, like something I should remember.” |
| Old key | Surprised | “An old key... Maybe it opens something Lola kept hidden.” |
| Old spoon | Neutral | “An old spoon. The handle is worn smooth from years of use.” |
| Bowl piece | Concerned | “A broken bowl piece. It was kept too carefully to be ordinary.” |
| Market receipt | Surprised | “An old La Paz market receipt. Chicharon is still readable, but the rest has faded.” |
| Family letter | Happy | “A letter from Lola. Her words feel like they were waiting for me.” |
| Third required item found | Happy | “These three feel important. I can close the box when I'm ready, but I may keep looking.” |
| All seven items found | Happy | “That's everything. I should clean this up and close the box.” |

Before all three required items are found, attempting to close the box picks
one concerned line at random:

1. “There should be something else in here. Am I not curious?”
2. “I've barely looked through this. There must be more.”
3. “Something important may still be buried underneath.”
4. “I shouldn't close this until I've checked more carefully.”
5. “Why stop now? This box still has something to show me.”

After all required items are found, closing uses the reusable
`SharedDialogue.ask()` conditional prompt:

- If optional items remain: “I found what I needed. Is that all I want from
  this box?” Choices: `Keep looking` / `Close the box`.
- If every item was investigated: “That's everything. Should I clean this up
  and close the box?” Choices: `Review memories` / `Close the box`.

`Keep looking` and `Review memories` resume gameplay. `Close the box` closes
the box and starts the collectible ending.
