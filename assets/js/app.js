import css from "../css/app.css"

import "phoenix_html"
import { Socket } from "phoenix"
import $ from 'jquery'

class Game {
  static init() {
    let socket = new Socket("/socket", {})

    let $join = $("#join_game")
    let $intro = $("#intro")
    let $game = $("#game")
    let $true_button = $("#true_button")
    let $false_button = $("#false_button")

    socket.connect()

    let channel = socket.channel("game:round", {})

    $join.on("click", e => {
      e.preventDefault()
      $intro.addClass("hide")
      $game.removeClass("hide")
      channel.join()
        .receive("ok", resp => {
          console.log("Joined successfully", resp)
        })
        .receive("error", resp => { console.log("Unable to join", resp) })
    })

  }
}

$(() => Game.init())
export default Game
