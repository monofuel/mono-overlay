# monomelon goal

- I have forks of melonds-ds and melonds
- we have a mono melon ebuild for building and compiler settings

- the goal is to get the game 'lost in blue' running at full performance on the anbernic rg ds plus with full melonds accuracy.
- the stock nnddss emulator can play lost in blue at 100% on the rg ds plus, but it is closed source and has graphical issues.

- melonds and melonds-ds are open source and accurate, which makes them fantastic to work with.

- the DS uses a fixed gpu pipeline, so our options are likely either pure software, or potentially compute shaders, but that sounds very difficult.
- we got a good % of improvement already from compiler setting tweaks.
- the remaining % of performance will likely have to be from tweaking melonds specifically for our hardware target?
