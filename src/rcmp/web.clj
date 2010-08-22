(ns rcmp.web
  (:use rcmp.notify
        compojure.core
        [hiccup core page-helpers]))

(defn home []
  (html [:head
          [:title "RCMP"]]
         [:body
          [:h1 "RCMP"]
          [:p "RCMP is a Github commit notification IRC bot."]]))

(defroutes web-routes
  (GET "/" [] (home)))
