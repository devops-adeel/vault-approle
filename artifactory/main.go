package main

import (
	"context"
	"fmt"
	"os"

	"github.com/adeelahmad84/go-artifactory/v2/artifactory"
	"github.com/adeelahmad84/go-artifactory/v2/artifactory/transport"
)

func Apikey(user string) string {
	tp := transport.BasicAuth{
		Username: os.Getenv("ARTIFACTORY_USERNAME"),
		Password: os.Getenv("ARTIFACTORY_PASSWORD"),
	}
	client, err := artifactory.NewClient(os.Getenv("ARTIFACTORY_URL"), tp.Client())
	if err != nil {
		fmt.Printf("\nerror: %v\n", err)
		return
	}
	key, _, err := client.V1.Security.CreateUserApiKey(context.Background(), user)
	if err != nil {
		fmt.Printf("\nerror: %v\n", err)
		return
	}
	return key
}

func StoreKey(s string) {

}

func main() {
	fmt.Println("Dude")
}
