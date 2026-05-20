package com.tj.app.market.coin;

import java.time.LocalDateTime;

import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

@Getter
@Setter
@ToString
public class CoinCommentDTO {

    private Long commentNo;
    private String symbol;
    private String content;
    private String username;
    private LocalDateTime createdAt;
    private String imageUrl;
    private String profileFileName;
    private long likeCount;
    private boolean likedByMe;
    private String type; // NEW / UPDATE / DELETE (broadcast only, not persisted)
}
