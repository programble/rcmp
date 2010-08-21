(ns rcmp.core
  (:use rcmp.notify
        rcmp.web
        [compojure.core :only [defroutes]]
        ring.adapter.jetty))

(defroutes all-routes
  web-routes
  notify-routes)

(defonce server (run-jetty #'all-routes {:port 8080 :join? false}))
