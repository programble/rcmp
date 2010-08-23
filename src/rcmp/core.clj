(ns rcmp.core
  (:use [rcmp notify web]
        [compojure.core :only [defroutes]]
        ring.adapter.jetty
        [ring.middleware reload stacktrace file file-info]))

(defroutes all-routes
  #'web-routes
  #'notify-routes)

(def app
     (-> #'all-routes
         (wrap-file "public")
         wrap-file-info
         ; Should probably remove these two for production
         (wrap-reload '[rcmp.web rcmp.notify])
         wrap-stacktrace))

(defonce server (run-jetty #'app {:port 8080 :join? false}))
