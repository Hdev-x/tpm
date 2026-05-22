package com.tj.app.market.community;

import java.time.LocalDateTime;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

@Getter
@Setter
@ToString
public class MarketCommentDTO {
    private Long commentNo;
    private String marketType;  // COIN or STOCK
    private String marketCode;  // symbol or stockCode
    private String content;
    private String username;
    private LocalDateTime createdAt;
    private String imageUrl;
    private String profileFileName;
    private long likeCount;
    private boolean likedByMe;
    private String type; // NEW / UPDATE / DELETE (broadcast only)
}
