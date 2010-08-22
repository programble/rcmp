(ns rcmp.web
  (:use rcmp.notify
        compojure.core))

; TODO: Build a nice web interface

(defroutes web-routes
  (GET "/" [] (->> (keys @irc-connections) (interpose " ") (apply str))))
