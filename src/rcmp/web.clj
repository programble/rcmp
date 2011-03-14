(ns rcmp.web
  (:use rcmp.notify
        compojure.core
        [hiccup core page-helpers]))

(defn home []
  (html [:head
          [:title "RCMP"]]
         [:body
          [:h1 "RCMP"]
          [:p "RCMP is a Github commit notification IRC bot."]
          [:h2 "Commit Hook URL"]
          [:p "http://rcmp.programble.co.cc/github/<server>/<channel>"]
          [:h2 "Connected to"]
          [:ul
           (for [server (keys @irc-connections)]
             [:li server])]]))

(defroutes web-routes
  (GET "/" [] (home)))
