package com.tj.app.market.index;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class MarketIndexDTO {
    private String name;
    private String price;
    private String change;
    private String changeRate;
    private boolean up;
    private List<Double> prices;
}
