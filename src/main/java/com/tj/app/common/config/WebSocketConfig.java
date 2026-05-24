package com.tj.app.common.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

/** ============================================================
 * [클래스 읽기] WebSocket(STOMP) 설정 클래스.
 *
 * @EnableWebSocketMessageBroker → STOMP 기반 WebSocket 메시지 브로커를 활성화한다.
 * 실시간 코인 시세, 주식 시세, 실시간 댓글 기능이 이 설정을 기반으로 동작한다.
 *
 * [전체 흐름]
 * 클라이언트(JS) → SockJS로 /ws-coin 또는 /ws-stock 에 연결
 *               → STOMP 프로토콜로 /topic/... 채널을 구독
 *               → 서버가 해당 채널로 메시지를 발행하면 구독자 전체에 전달
 * ============================================================ */
@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    /** ============================================================
     * 메시지 브로커 설정.
     *
     * enableSimpleBroker("/topic") →
     *   /topic 으로 시작하는 채널을 인메모리 브로커가 관리한다.
     *   서버에서 /topic/coin/BTCUSDT 로 발행하면 해당 채널 구독자 전체에 전달.
     *
     * setApplicationDestinationPrefixes("/app") →
     *   클라이언트가 /app/... 로 메시지를 보내면 @MessageMapping 메서드로 라우팅된다.
     *   (현재 프로젝트에서는 주로 서버→클라이언트 단방향 전송만 사용 중)
     * ============================================================ */
    @Override
    public void configureMessageBroker(MessageBrokerRegistry registry) {
        registry.enableSimpleBroker("/topic");
        registry.setApplicationDestinationPrefixes("/app");
    }

    /** ============================================================
     * STOMP WebSocket 엔드포인트 등록.
     *
     * /ws-coin  → 코인 실시간 시세·댓글용 WebSocket 연결 주소
     * /ws-stock → 주식 실시간 시세·댓글용 WebSocket 연결 주소
     * withSockJS() → WebSocket을 지원하지 않는 브라우저에서도
     *                HTTP 롱폴링 등으로 자동 폴백 처리된다.
     * ============================================================ */
    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws-coin").withSockJS();
        registry.addEndpoint("/ws-stock").withSockJS();
    }
}
