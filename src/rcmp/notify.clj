(ns rcmp.notify
  (:use [compojure.core :only [defroutes POST]]
        irclj.irclj
        rcmp.utilities
        [clojure.contrib.string :only [split]]
        clojure.contrib.json))

(defonce irc-connections (atom {}))

(defn in-channel? [irc channel]
  (some #(= % channel) (:channels @irc)))

(defn format-commit [commit url?]
  (str (when url?
         (str "<" (is-gd (:url commit)) "> "))
       "\u0002"
       (:name (:author commit))
       "\u0002: "
       (apply str (take 8 (:id commit)))
       " \u0002[\u0002"
       (->> [(map #(str "+" %) (:added commit))
             (map #(str "-" %) (:removed commit))
             (map #(str %) (:modified commit))]
            (flatten)
            (interpose " ")
            (apply str))
       "\u0002]\u0002 "
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
  (println (format "(notify %s %d %s %s)" server port channel (str payload)))
  (when (= (:name (:repository payload) "rcmp"))
    (println (clojure.java.shell/sh "git" "pull")))
  (if-let [irc (get @irc-connections server)]
    (if (.isClosed (:sock (:connection @irc)))
      (do
        (swap! irc-connections dissoc server)
        (notify server port channel payload))
      (do
        (when-not (in-channel? irc channel)
          (join-chan irc channel))
        (doseq [line (format-notification payload)]
          (send-message irc channel line))))
    (let [on-connect (fn [{:keys [irc]}] (join-chan irc channel) (doseq [line (format-notification payload)] (send-message irc channel line)))
          irc (connect (create-irc {:name "RCMP" :server server :port port :fnmap {:on-connect on-connect}}))]
      (swap! irc-connections assoc server irc)
      (println (str "@irc-connections: " @irc-connections)))))

(defroutes notify-routes
  (POST ["/github/:server/:port/:channel"
         :server #".+"
         :port #"\d+"
         :channel #".+"]
        [server port channel payload]
        (in-thread (notify server (read-string port) (str "#" channel) (read-json payload)))
        "Notification sent")
  (POST ["/github/:server/:channel"
         :server #".+"
         :channel #".+"]
        [server channel payload]
        (in-thread (notify server 6667 (str "#" channel) (read-json payload)))
        "Notification sent"))
