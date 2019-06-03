# Mathracer - simple multiplayer math challenge game game

The game is structured as a continuous series of rounds, where all connected players compete to submit the correct answer first. 

Number of rounds is not limited, players can connect at any time and start competing. - limit number of socket connections


At the beginning of each round a simple math challenge is sent to all connected players, consisting of a basic operation (+ - * /), two operands in range 1..10 and a potential answer. 

All players are presented with the challenge and have to answer whether the proposed answer is correct using a simple yes/no choice.

A new round starts in 5 seconds after the end of last one.

Setup instructions:
  * Install elixir with `brew install elixir`
  * Install dependencies with `mix deps.get`
  * Install Node.js dependencies with `cd assets && npm install`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.