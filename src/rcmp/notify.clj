(ns rcmp.notify
  (:use [compojure.core :only [defroutes POST]]
        irclj.irclj
        rcmp.utilities
        [clojure.contrib.string :only [split]])
  (:require [org.danlarkin [json :as json]]))

(defonce irc-connections (atom {}))

(defn in-channel? [irc channel]
  (some #(= % channel) (:channels @irc)))

(defn format-commit [commit url?]
  (str (when url?
         (str "<" (is-gd (:url commit)) "> "))
       (:name (:author commit))
       ": "
       (apply str (take 8 (:id commit)))
       " ["
       (->> [(map #(str "+" %) (:added commit))
             (map #(str "-" %) (:removed commit))
             (map #(str %) (:modified commit))]
            (flatten)
            (interpose " ")
            (apply str))
       "] "
       (:message commit)))

(defn format-notification [payload]
  (if (> (count (:commits payload)) 1)
    (into [(str "\u0002"
                (:name (:owner (:repository payload)))
                "/"
                (:name (:repository payload))
                "\u0002: "
                (count (:commits payload))
                " commits on "
                (->> (:ref payload) (split #"/") (last))
                " <"
                (is-gd (:compare payload))
                "> "
                (:open_issues (:repository payload))
                " open issues")]
          (for [commit (take 3 (:commits payload))]
            (format-commit commit false)))
    (for [commit (:commits payload)]
      (str "\u0002"
           (:name (:owner (:repository payload)))
           "/"
           (:name (:repository payload))
           "\u0002: "
           (->> (:ref payload) (split #"/") (last))
           " "
           (format-commit commit true)))))
         
(defn notify [server port channel payload]
  (if-let [irc (get @irc-connections server)]
    (do
      (when-not (in-channel? irc channel)
        (join-chan irc channel))
      (doseq [line (format-notification payload)]
        (send-message irc channel line)))
    (let [on-connect (fn [{:keys [irc]}] (doseq [line (format-notification payload)] (send-message irc channel line)))
          irc (connect (create-irc {:name "RCMP" :server server :port port :fnmap {:on-connect on-connect}}) :channels [channel])]
      (swap! irc-connections assoc server irc))))

(defroutes notify-routes
  (POST ["/github/:server/:port/:channel"
         :server #".+"
         :port #"\d+"
         :channel #".+"]
        [server port channel payload]
        (in-thread (notify server (read-string port) (str "#" channel) (json/decode-from-str payload)))
        "Notification sent")
  (POST ["/github/:server/:channel"
         :server #".+"
         :channel #".+"]
        [server channel payload]
        (in-thread (notify server 6667 (str "#" channel) (json/decode-from-str payload)))
        "Notification sent"))
