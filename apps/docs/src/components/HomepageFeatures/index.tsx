import React from "react";
import clsx from "clsx";
import Heading from "@theme/Heading";
import styles from "./styles.module.css";
import useBaseUrl from "@docusaurus/useBaseUrl";

type FeatureItem = {
  title: string;
  gifPath: string;
};

const FeatureList: FeatureItem[] = [
  {
    title: "🤖 Android Support",
    gifPath: "img/android.gif",
  },
  {
    title: "🍎 iOS support",
    gifPath: "img/ios.gif",
  },
  {
    title: "🌐 Web support",
    gifPath: "img/web.gif",
  },
  {
    title: "🍏 iPadOS support",
    gifPath: "img/ipados.gif",
  },
];

function Feature({ title, gifPath }: FeatureItem) {
  return (
    <div className={clsx("col col--4")}>
      <div className="text--center">
        {!!gifPath && (
          <svg xmlns="http://www.w3.org/2000/svg" width="283" height="460">
            <image
              href={useBaseUrl(gifPath)}
              x="18"
              y="33"
              width="247"
              height="469"
            />
          </svg>
        )}
      </div>
      <div className="text--center padding-horiz--md">
        <Heading as="h3">{title}</Heading>
      </div>
    </div>
  );
}

export default function HomepageFeatures(): React.JSX.Element {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row" style={{ justifyContent: "center" }}>
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}
