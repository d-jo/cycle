package main

import (
	"github.com/gorilla/mux"
	"log"
	"net/http"
	"time"
)

func main() {

	rootHandler := mux.NewRouter()

	// api
	rootHandler.Handle("/")

	srv := &http.Server{
		Handler:      rootHandler,
		WriteTimeout: 15 * time.Second,
		ReadTimeout:  15 * time.Second,
	}

	log.Fatal(srv.ListenAndServe())

}
