(ns rcmp.utilities
  (:use [clojure-http.client :only [add-query-params]])
  (:require [clojure-http.resourcefully :as res]))

(defn is-gd [url]
  (-> (res/get (add-query-params "http://is.gd/api.php" {"longurl" url})) :body-seq first))