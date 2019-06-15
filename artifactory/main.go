package main

import (
	"context"
	"fmt"
	"net/http"
	"os"

	"github.com/atlassian/go-artifactory/v2/artifactory"
	"github.com/atlassian/go-artifactory/v2/artifactory/client"
	"github.com/atlassian/go-artifactory/v2/artifactory/transport"
)

type Service struct {
	client *client.Client
}

type SecurityService Service

type ApiKey struct {
	ApiKey *string `json:"apiKey,omitempty"`
}

func (s *SecurityService) CreateUserApiKey(ctx context.Context, username string) (*ApiKey, *http.Response, error) {
	path := fmt.Sprintf("/api/security/apiKey/%s", username)
	req, err := s.client.NewRequest("POST", path, nil)
	if err != nil {
		return nil, nil, err
	}
	req.Header.Set("Accept", client.MediaTypeJson)

	v := new(ApiKey)
	resp, err := s.client.Do(ctx, req, v)
	return v, resp, err
}

func main() {
	tp := transport.BasicAuth{
		Username: os.Getenv("ARTIFACTORY_USERNAME"),
		Password: os.Getenv("ARTIFACTORY_PASSWORD"),
	}

	client, err := artifactory.NewClient(os.Getenv("ARTIFACTORY_URL"), tp.Client())
	if err != nil {
		fmt.Printf("\nerror: %v\n", err)
		return
	}
	//TODO: @this point the package itself will need to be modified and imported.
}
