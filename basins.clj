(ns solution
  (:gen-class))

(defn valid-coord?
  [matrix [row col]]
  (let [size (count matrix)]
    (and (< row size) (not (neg? row))
         (< col size) (not (neg? col)))))

(def ^:private neighbor-offsets
  [[-1 -1] [-1 0] [-1 1] [0 -1] [0 1] [1 -1] [1 0] [1 1]])

(defn neighbors
  [matrix [row col]]
  (let [possible-neighbors (map (fn [[row-offset col-offset]]
                                  [(+ row row-offset) (+ col col-offset)])
                                neighbor-offsets)]
    (filter (partial valid-coord? matrix) possible-neighbors)))

(defn lowest-neighbor
  [matrix coord]
  (apply min-key (partial get-in matrix) (neighbors matrix coord)))

(defn lower?
  [matrix coord1 coord2]
  (<= (get-in matrix coord1) (get-in matrix coord2)))

(defn all-coords
  [matrix]
  (let [size (count matrix)]
    (for [row (range size)
          col (range size)]
      [row col])))

(defn sinks
  [matrix]
  (filter
    #(every? (partial lower? matrix %) (neighbors matrix %))
    (all-coords matrix)))

(defn source-of?
  [matrix destination source]
  (and (lower? matrix destination source)
       (= destination (lowest-neighbor matrix source))))

(defn sources
  [matrix coord]
  (let [direct-sources (filter (partial source-of? matrix coord)
                               (neighbors matrix coord))]
    (apply concat [coord]
           (map (partial sources matrix) direct-sources))))

(defn basins
  [matrix]
  (map (partial sources matrix) (sinks matrix)))

(defn- read-row
  [_]
  (vec (map #(Integer/parseInt %)
            (clojure.string/split (read-line) #" "))))

(defn -main
  []
  (let [size (Integer/parseInt (read-line))
        matrix (vec (map read-row (range size)))
        basin-sizes (map count (basins matrix))]
    (println (clojure.string/join " " (sort > basin-sizes)))))
