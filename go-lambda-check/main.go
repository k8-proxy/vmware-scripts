package main

import (
	"fmt"

	"github.com/icapeg-client/client"

	"github.com/aws/aws-lambda-go/lambda"
)

type MyEvent struct {
	Host     string `json:"host"`
	Exitcode string `json:"test"`
}

type MyResponse struct {
	Message string `json:"exitcode:"`
}

func HandleLambdaEvent(event MyEvent) (MyResponse, error) {
	event.Exitcode = "1"

	fmt.Println("start test")
	fmt.Println(event.Host)

	result := client.Clienticap(event.Host)
	if result != "0" {
		fmt.Println("not healthy server")
		event.Exitcode = "1"

	} else {
		fmt.Println("healthy server")
		event.Exitcode = "0"

	}
	return MyResponse{Message: fmt.Sprintf("%s", event.Exitcode)}, nil

}

func main() {
	lambda.Start(HandleLambdaEvent)

}
