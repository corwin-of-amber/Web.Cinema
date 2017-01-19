
class Hist

  ->
    if localStorage.history
      @items = JSON.parse that
    else
      @items = []

  save: !->
    localStorage.history = JSON.stringify @items


$ ->
  window.hist = new Hist
  /*
  indexedDB.open('wcHistory', 2)
    ..onerror ->
      werr "[history] #{JSON.stringify it}"
    ..onupgradeneeded ->
      env = it.target.result
      env.createObjectStore("historyItems")
  */
