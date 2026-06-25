# (fig) specific cancer site bubble plot

library(ggplot2)
library(readxl)
library(tidyverse)
library(ggnewscale)

# Font: Wiley requirement
font_family <- "Arial" # Helvetica

# import dataset
total <- read_excel("path/to/FHx_Fig.xlsx")

# order of labels 
total$FH1 <- factor(total$FH, levels = unique(total$FH), ordered = T)
total$CANCER1 <- factor(total$CANCER, levels = unique(total$CANCER), ordered = T)
total$CANCER2 <- fct_rev(total$CANCER1)
total$HR_num <- as.numeric(total$HR)
total$HR_label <- sprintf("%.2f", total$HR_num)


# legend 순서
total$effect_direction <- ifelse(total$HR < 1, "Decreased", "Increased")
total$effect_direction <- factor(total$effect_direction,
                                 levels = c("Decreased", "Increased"))

p <- ggplot(total,
       aes(x = FH1, 
           y = CANCER2,
           size = HR_num,
           shape = `Statistically significant`)) +
  geom_point(aes(colour=effect_direction),
             alpha = 0.75,
             stroke = 1.5) +   # shape=1
  scale_shape_manual(values=c(1, 16))+
  scale_color_manual(name = "Effect direction",
                     values = c("Decreased" = "deepskyblue",
                              "Increased" = "sienna1"),
                     labels = c("Decreased", "Increased")) +
  geom_text(aes(label = HR_label),
            family = font_family,
            size = 4,
            show.legend = FALSE) +
  scale_x_discrete(position = "top") +
  scale_size_continuous( name = "HR",
                         range = c(8, 18),
                         breaks = c(0.5, 1.0, 1.5, 2.0)) + # Adjust as required.
  labs(x="Family history of cancer", y = "Cancer site") +
  guides(
    shape = guide_legend(order = 1),
    colour = guide_legend(order = 2),
    size = guide_legend(order = 3)
  ) +
  theme_bw(base_family = font_family) +
  theme(
    plot.title = element_text(colour = "black", size=20,
                              face = "bold", hjust = 0.5),
    axis.title.x =   element_text(colour = "black", size = 16, 
                                  face = "bold", hjust = 0.5),
    axis.title.y =   element_text(colour = "black", size = 16, 
                                  face = "bold", hjust = 0.5),
    axis.text.x = element_text(colour = "black", size = 12, 
                               face = "bold", hjust = 0.5), 
    axis.text.y = element_text(colour = "black", 
                               face = "bold", size = 12), 
    panel.background = element_blank(),
    panel.border = element_blank(), 
    legend.title = element_text(size=14),
    legend.text = element_text(size=12, color="black"),
    legend.position = "right",
    legend.box = "vertical",
    legend.justification = "center",
    legend.box.just = "left",
    panel.grid = element_blank(),
    axis.ticks = element_blank())

# Vector PDF
ggsave(
  filename = "Figure1.pdf",
  plot = p,
  device = grDevices::cairo_pdf,
  width = 9,
  height = 11,
  units = "in",
  family = font_family,
  fallback_resolution = 1000,
  bg = "white"
)
