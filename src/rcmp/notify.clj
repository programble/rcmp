(ns rcmp.notify
  (:use [compojure.core :only [defroutes POST]]
        irclj.irclj
        rcmp.utilities
        [clojure.contrib.string :only [split]])
  (:require [org.danlarkin [json :as json]]))

(defonce irc-connections (atom {}))

(defn in-channel? [irc channel]
  (some #(= % channel) (:channels @irc)))

(defn format-notification [payload]
  (for [commit (:commits payload)]
    (str (:name (:owner (:repository payload)))
         "/"
         (:name (:repository payload))
         ":"
         (->> (:ref payload) (split #"/") (last))
         " <"
         (is-gd (:url commit))
         "> "
         (:name (:author commit))
         ": ["
         (apply str (interpose " " (flatten [(map #(str "+" %) (:added commit))
                                       (map #(str "-" %) (:removed commit))
                                       (map #(identity) (:modified commit))])))
         "] "
         (:message commit))))

(defn notify [server port channel payload]
  (if-let [irc (get @irc-connections server)]
    (do
      (when-not (in-channel? irc channel)
        (join-chan irc channel))
      (doseq [line (format-notification payload)]
        (send-message irc channel line)))
    (let [irc (connect (create-irc {:name "RCMP" :server server :port port :fnmap {}}) :channels [channel])]
      (swap! irc-connections assoc server irc)
      (Thread/sleep 10000)
      (doseq [line (format-notification payload)]
        (send-message irc channel line)))))

(defroutes notify-routes
  (POST ["/:server/:port/:channel"
         :server #".+"
         :port #"\d+"
         :channel #".+"]
        [server port channel payload]
        (notify server (read-string port) (str "#" channel) (json/decode-from-str payload))
        "Notification sent")
  (POST ["/:server/:channel"
         :server #".+"
         :channel #".+"]
        [server channel payload]
        (notify server 6667 (str "#" channel) (json/decode-from-str payload))
        "Notification sent"))
