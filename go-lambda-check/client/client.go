package client

import (
	"fmt"
	"io"
	"net/http"

	"os"
	"time"

	ic "github.com/egirna/icap-client"
)

//ICAP
func Clienticap(server string) string {
	//ic.SetDebugMode(true)
	var requestHeader http.Header
	//file, host, port, service, timeout, filepath := config.Configtoml()

	file := "http://www.africau.edu/images/default/sample.pdf"
	//filepath := "client/sample.pdf"
	filepath := "/tmp/sample.pdf"
	host := server //"eu.icap.glasswall-icap.com"   "51.141.25.5"

	port := "1344"
	service := "gw_rebuild"
	timeout := time.Duration(40) * time.Second
	/*fmt.Println(file)
	     us.icap.glasswall-icap.com
		fmt.Println(host)
		fmt.Println(port)
		fmt.Println(service)
		fmt.Println(timeout)
		fmt.Println(filepath)*/

	httpReq, err := http.NewRequest(http.MethodGet, file, nil)

	if err != nil {
		fmt.Println(err)
		return "httpReq error: " + err.Error()

	}

	httpClient := &http.Client{}
	httpResp, err := httpClient.Do(httpReq)

	if err != nil {
		fmt.Println(err)
		return "httpResp error: " + err.Error()

	}
	//var httpRequest *http.Request
	//var httpResponse *http.Response

	icap := "icap://" + host + ":" + port + "/" + service
	req, err := ic.NewRequest(ic.MethodRESPMOD, icap, httpReq, httpResp)

	if err != nil {
		fmt.Println(err)
		return "icap error: " + err.Error()

	}

	req.ExtendHeader(requestHeader)

	client := &ic.Client{
		Timeout: timeout * time.Millisecond,
	}

	resp, err := client.Do(req)

	if err != nil {
		fmt.Println(err)
		return "resp error: " + err.Error()

	}

	optReq, err := ic.NewRequest(ic.MethodOPTIONS, icap, nil, nil)

	if err != nil {
		fmt.Println(err)
		return "optReq error: " + err.Error()
	}
	//	client := &ic.Client{
	//		Timeout: 5 * time.Second,
	//	}
	optResp, err := client.Do(optReq)

	if err != nil {
		fmt.Println(err)
		return "optResp error: " + err.Error()
	}

	req.SetPreview(optResp.PreviewBytes)
	/*
		fmt.Println(resp.StatusCode)
		fmt.Println(resp.Status)
		fmt.Println(resp.PreviewBytes)
		fmt.Println(resp.Header)
		fmt.Println(resp.ContentRequest)
		fmt.Println(resp.ContentResponse)
	*/

	samplefile, err := os.Create(filepath)
	if err != nil {
		fmt.Println(err)
		return "samplefile error: " + err.Error()

		//os.Exit(1)
	}
	defer samplefile.Close()
	//x.Write(samplefile)
	io.Copy(samplefile, resp.ContentResponse.Body)
	return "0"
}
