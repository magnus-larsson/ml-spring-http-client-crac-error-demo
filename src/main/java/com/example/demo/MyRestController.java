package com.example.demo;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.reactive.function.client.WebClient;

import reactor.core.publisher.Mono;

@RestController
@RequestMapping("/")
public class MyRestController {
    
	private final RestTemplate restTemplate;
	private final RestClient restClient;
	private final WebClient webClient;

	public MyRestController(RestTemplate restTemplate, RestClient restClient, WebClient.Builder webClientBuilder) {
		this.restTemplate = restTemplate;
		this.restClient = restClient;
		this.webClient = webClientBuilder.build();
	}

	@GetMapping("/usingRestTemplate")
	String requestUsingRestTemplate() {
		return restTemplate.getForObject("https://httpbin.org/uuid", String.class);
	}

	@GetMapping("/usingRestClient")
	String requestUsingRestClient() {
		return restClient.get().uri("https://httpbin.org/uuid").retrieve().body(String.class);
	}

	@GetMapping("/usingWebClient")
	Mono<String> requestUsingWebClient() {
	    return webClient.get().uri("https://httpbin.org/uuid").retrieve().bodyToMono(String.class);
	}

}
