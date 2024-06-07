'use client';
import Image from "next/image";
import { ConnectButton } from "thirdweb/react";
import thirdwebIcon from "@public/thirdweb.svg";
import { client } from "./client";
import { useState } from "react";
import RuleItem from "./components/ruleItem";

export default function Home() {
  const [result, setResult] = useState('')
  const [rules, setRules] = useState([
    ['', ''],
  ])
  const addRule = () => {
    if (rules.length >= 36) return
    setRules([...rules, ['', '']])
  }

  const [checked, setChecked] = useState(false)
  return (
    <main className="p-4 pb-10 min-h-[100vh] flex flex-col items-center container max-w-screen-lg mx-auto">
      <Header />
      <div className="container-content  w-full">
        <div className="flex gap-14">
          <div className="card flex flex-col gap-4 flex-1">
          <p className="">Ruleset</p>
            {
              rules.map((rule, index) => (
                <RuleItem key={index}></RuleItem>
              ))
            }
            <button className="btn" onClick={addRule}> Add + </button>

          </div>
          <div className="flex flex-col gap-4 flex-1">
            <div>
              <p className="pb-4">Description</p>
              <textarea className="textarea textarea-bordered w-full" placeholder="Description..."></textarea>
            </div>
            <div>
              <p className="pb-4">Available</p>
              <input type="checkbox" className="toggle" onChange={() => (setChecked(!checked))} checked={checked} />
            </div>
          </div>

        </div>
      </div>
    </main>
  );
}

function Header() {
  return (
    <header className="flex items-center justify-end h-20 w-full">
      <div className="dropdown dropdown-hover">
        <ConnectButton
          client={client}
          appMetadata={{
            name: "No lie",
            url: "https://github.com/Nauxscript/no-lie-lottery-machine",
          }}
        />
        {/* <div tabIndex={0} role="button" className="btn m-1">Click</div> */}
        <ul tabIndex={0} className="dropdown-content z-[1] menu p-2 shadow rounded-box w-52">
          <li><a>My Rulesets</a></li>
          <li><a>My Rewards</a></li>
        </ul>
      </div>
    </header>
  )
}

function _Header() {
  return (
    <header className="flex flex-col items-center mb-20 md:mb-20">
      <Image
        src={thirdwebIcon}
        alt=""
        className="size-[150px] md:size-[150px]"
        style={{
          filter: "drop-shadow(0px 0px 24px #a726a9a8)",
        }}
      />

      <h1 className="text-2xl md:text-6xl font-semibold md:font-bold tracking-tighter mb-6 text-zinc-100">
        thirdweb SDK
        <span className="text-zinc-300 inline-block mx-1"> + </span>
        <span className="inline-block -skew-x-6 text-blue-500"> Next.js </span>
      </h1>

      <p className="text-zinc-300 text-base">
        Read the{" "}
        <code className="bg-zinc-800 text-zinc-300 px-2 rounded py-1 text-sm mx-1">
          README.md
        </code>{" "}
        file to get started.
      </p>
    </header>
  );
}

function ThirdwebResources() {
  return (
    <div className="grid gap-4 lg:grid-cols-3 justify-center">
      <ArticleCard
        title="thirdweb SDK Docs"
        href="https://portal.thirdweb.com/typescript/v5"
        description="thirdweb TypeScript SDK documentation"
      />

      <ArticleCard
        title="Components and Hooks"
        href="https://portal.thirdweb.com/typescript/v5/react"
        description="Learn about the thirdweb React components and hooks in thirdweb SDK"
      />

      <ArticleCard
        title="thirdweb Dashboard"
        href="https://thirdweb.com/dashboard"
        description="Deploy, configure, and manage your smart contracts from the dashboard."
      />
    </div>
  );
}

function ArticleCard(props: {
  title: string;
  href: string;
  description: string;
}) {
  return (
    <a
      href={props.href + "?utm_source=next-template"}
      target="_blank"
      className="flex flex-col border border-zinc-800 p-4 rounded-lg hover:bg-zinc-900 transition-colors hover:border-zinc-700"
    >
      <article>
        <h2 className="text-lg font-semibold mb-2">{props.title}</h2>
        <p className="text-sm text-zinc-400">{props.description}</p>
      </article>
    </a>
  );
}
